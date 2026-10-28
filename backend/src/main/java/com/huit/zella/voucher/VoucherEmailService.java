package com.huit.zella.voucher;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.customer.CustomerRepository;
import com.huit.zella.mail.EmailQueue;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.text.NumberFormat;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Service
public class VoucherEmailService {
    private static final Set<String> TIERS = Set.of("STANDARD", "SILVER", "GOLD");
    private final VoucherRepository vouchers;
    private final CustomerRepository customers;
    private final VoucherEmailRecipientRepository recipients;
    private final EmailQueue queue;
    private final VoucherEmailBatchWriter batch;
    private final Clock clock;
    private final long spacingMs;

    public VoucherEmailService(VoucherRepository vouchers, CustomerRepository customers,
            VoucherEmailRecipientRepository recipients, EmailQueue queue, VoucherEmailBatchWriter batch, Clock clock,
            @Value("${app.mail.voucher-spacing-ms:3000}") long spacingMs) {
        this.vouchers = vouchers; this.customers = customers; this.recipients = recipients;
        this.queue = queue; this.batch = batch; this.clock = clock; this.spacingMs = Math.max(1000, spacingMs);
    }

    public record Recipient(String name, String email, String tier) {}
    public record Preview(int eligible, int alreadyQueued, int invalidEmails, int toQueue,
                          Integer remainingUses, String audienceKey, List<Recipient> sample,
                          String subject, String emailBody) {}
    public record SendResult(int queued, int alreadyQueued) {}
    private record Audience(List<Recipient> pending, int alreadyQueued, int invalidEmails) {}

    @Transactional(readOnly = true)
    public Preview preview(Long id, Set<String> tiers) {
        validateTiers(tiers);
        Voucher voucher = voucher(id, false);
        Audience audience = audience(id, tiers);
        return new Preview(audience.pending().size() + audience.alreadyQueued(), audience.alreadyQueued(),
                audience.invalidEmails(), audience.pending().size(), remaining(voucher),
                key(voucher, tiers, audience), audience.pending().stream().limit(20).toList(), subject(voucher),
                audience.pending().isEmpty() ? "" : body(voucher, audience.pending().getFirst()));
    }

    @Transactional
    public SendResult send(Long id, Set<String> tiers, String audienceKey) {
        validateTiers(tiers);
        // All sends for one voucher serialize on its row, including requests with overlapping tiers.
        Voucher voucher = voucher(id, true);
        Audience audience = audience(id, tiers);
        if (!key(voucher, tiers, audience).equals(audienceKey))
            throw new BusinessException(HttpStatus.CONFLICT, "VOUCHER_AUDIENCE_CHANGED",
                    "Voucher hoặc danh sách người nhận đã thay đổi. Vui lòng xem trước lại trước khi gửi.");
        Instant now = clock.instant();
        Instant expiresAt = voucher.getEndDate().toInstant(ZoneOffset.UTC);
        // Do not schedule mail that will already be expired when its delivery slot arrives.
        if (!audience.pending().isEmpty()
                && !now.plusMillis(Math.multiplyExact((long) audience.pending().size() - 1, spacingMs)).isBefore(expiresAt))
            throw error("Voucher sắp hết hạn, không đủ thời gian gửi cho nhóm đã chọn. Hãy giảm số hạng hoặc gia hạn voucher.");
        int index = 0;
        List<VoucherEmailBatchWriter.Message> messages = new ArrayList<>();
        for (Recipient recipient : audience.pending()) {
            messages.add(new VoucherEmailBatchWriter.Message(recipient.email(), recipient.tier(), subject(voucher),
                    body(voucher, recipient), now.plusMillis(index++ * spacingMs), expiresAt));
        }
        batch.enqueue(id, now, messages);
        return new SendResult(index, audience.alreadyQueued());
    }

    private void validateTiers(Set<String> tiers) {
        if (tiers == null || tiers.isEmpty() || !TIERS.containsAll(tiers)) throw error("Vui lòng chọn hạng Thường, Bạc hoặc Vàng.");
        if (!queue.enabled()) throw new BusinessException(HttpStatus.SERVICE_UNAVAILABLE, "EMAIL_UNAVAILABLE", "Chức năng email chưa được bật.");
    }

    private Voucher voucher(Long id, boolean lock) {
        Voucher voucher = (lock ? vouchers.lock(id) : vouchers.findById(id))
                .orElseThrow(() -> error("Không tìm thấy voucher."));
        if (voucher.getOwner() != null || voucher.isRedeemable() || voucher.getSourceRewardId() != null)
            throw error("Chỉ gửi mã voucher dùng chung; không gửi mẫu đổi điểm hoặc voucher đã cấp riêng.");
        LocalDateTime now = LocalDateTime.ofInstant(clock.instant(), ZoneOffset.UTC);
        if (!voucher.isActive() || voucher.getStartDate() == null || voucher.getEndDate() == null
                || voucher.getStartDate().isAfter(now) || !voucher.getEndDate().isAfter(now))
            throw error("Voucher phải đang bật và trong thời gian có hiệu lực.");
        if (remaining(voucher) != null && remaining(voucher) <= 0) throw error("Voucher đã hết lượt sử dụng.");
        return voucher;
    }

    private Integer remaining(Voucher voucher) {
        return voucher.getUsageLimit() == null ? null : Math.max(0, voucher.getUsageLimit() - voucher.getUsedCount());
    }

    private Audience audience(Long id, Set<String> tiers) {
        Set<String> queued = new HashSet<>(recipients.queuedEmails(id));
        Map<String, Recipient> unique = new TreeMap<>();
        int invalid = 0;
        var page = PageRequest.of(0, 500);
        org.springframework.data.domain.Slice<CustomerRepository.VoucherEmailRecipient> slice;
        do {
            slice = customers.voucherEmailRecipients(tiers, page);
            for (var customer : slice) {
                String email = customer.getEmail() == null ? "" : customer.getEmail().trim().toLowerCase(Locale.ROOT);
                if (!validEmail(email)) { invalid++; continue; }
                unique.putIfAbsent(email, new Recipient(customer.getFullName(), email, customer.getMembershipTier()));
            }
            page = page.next();
        } while (slice.hasNext());
        int already = 0;
        List<Recipient> pending = new ArrayList<>();
        for (var recipient : unique.values()) {
            if (queued.contains(recipient.email())) already++;
            else pending.add(recipient);
        }
        return new Audience(pending, already, invalid);
    }

    private boolean validEmail(String email) {
        if (email.isBlank() || email.length() > 254 || email.contains("\r") || email.contains("\n")) return false;
        try {
            var address = new jakarta.mail.internet.InternetAddress(email, true);
            address.validate();
            return address.getPersonal() == null && email.equals(address.getAddress());
        } catch (jakarta.mail.internet.AddressException invalid) {
            return false;
        }
    }

    private String key(Voucher voucher, Set<String> tiers, Audience audience) {
        // Hash exactly what is being confirmed, including voucher terms and recipient snapshots.
        String terms = List.of(voucher.getId(), voucher.getCode(), Objects.toString(voucher.getName(), ""),
                Objects.toString(voucher.getDescription(), ""), voucher.getDiscountType(), voucher.getDiscountValue(),
                voucher.getMinOrderAmount(), voucher.getDiscountAmount(), voucher.getStartDate(), voucher.getEndDate(),
                Objects.toString(voucher.getUsageLimit(), "unlimited"), new TreeSet<>(tiers), audience.pending()).toString();
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(terms.getBytes(StandardCharsets.UTF_8))); }
        catch (NoSuchAlgorithmException failure) { throw new IllegalStateException(failure); }
    }

    private String body(Voucher voucher, Recipient recipient) {
        NumberFormat money = NumberFormat.getCurrencyInstance(Locale.forLanguageTag("vi-VN"));
        String discount = "PERCENT".equals(voucher.getDiscountType())
                ? voucher.getDiscountValue().stripTrailingZeros().toPlainString() + "%" : money.format(voucher.getDiscountValue());
        String tier = switch (recipient.tier()) { case "SILVER" -> "Bạc"; case "GOLD" -> "Vàng"; default -> "Thường"; };
        StringBuilder body = new StringBuilder("Xin chào ").append(recipient.name())
                .append(",\n\nZELLA gửi bạn ưu đãi dành cho khách hạng ").append(tier)
                .append(".\n\n").append(Objects.toString(voucher.getName(), "Ưu đãi ZELLA"))
                .append("\nMã voucher: ").append(voucher.getCode()).append("\nGiảm: ").append(discount)
                .append("\nĐơn tối thiểu: ").append(money.format(voucher.getMinOrderAmount()));
        if ("PERCENT".equals(voucher.getDiscountType()) && voucher.getDiscountAmount().compareTo(BigDecimal.ZERO) > 0)
            body.append("\nGiảm tối đa: ").append(money.format(voucher.getDiscountAmount()));
        DateTimeFormatter date = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm").withZone(ZoneId.of("Asia/Ho_Chi_Minh"));
        body.append("\nHạn sử dụng: ").append(date.format(voucher.getEndDate().toInstant(ZoneOffset.UTC)))
                .append(" (giờ Việt Nam)");
        if (voucher.getDescription() != null && !voucher.getDescription().isBlank()) body.append("\n").append(voucher.getDescription());
        body.append("\n\nNhập mã ở bước thanh toán. Ưu đãi áp dụng theo điều kiện và số lượt còn lại tại thời điểm đặt hàng; email không giữ trước lượt sử dụng.")
                .append("\n\nCảm ơn bạn đã đồng hành cùng ZELLA.");
        return body.toString();
    }

    private String subject(Voucher voucher) {
        return "ZELLA - Voucher " + voucher.getCode() + " dành cho bạn";
    }

    private BusinessException error(String message) {
        return new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_VOUCHER_EMAIL", message);
    }
}
