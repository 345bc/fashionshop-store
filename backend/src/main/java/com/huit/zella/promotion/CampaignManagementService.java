package com.huit.zella.promotion;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.ProductRepository;
import com.huit.zella.voucher.*;
import com.huit.zella.order.OrderRepository;

import java.math.BigDecimal;
import java.time.*;
import java.util.*;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CampaignManagementService {
    private final VoucherRepository vouchers;
    private final PromotionRepository promotions;
    private final ProductRepository products;
    private final OrderRepository orders;
    private final Clock orderClock;

    @Transactional(readOnly = true)
    public List<CampaignResponse> list(String kind) {
        checkKind(kind);
        return "voucher".equals(kind) ? vouchers.findByOwnerIsNullOrderByIdDesc().stream().map(v -> response(v, false)).toList()
                : promotions.findAllByOrderByIdDesc().stream().map(this::response).toList();
    }

    @Transactional(readOnly = true)
    public List<CampaignResponse.ProductOption> catalog() {
        return products.findAll(org.springframework.data.domain.Sort.by("id").descending()).stream()
                .filter(p -> p.isActive() && Boolean.TRUE.equals(p.getCategory().getIsActive()))
                .map(p -> new CampaignResponse.ProductOption(p.getId(), p.getName())).toList();
    }

    @Transactional(readOnly = true)
    public CampaignResponse detail(String kind, Long id) {
        checkKind(kind);
        return "voucher".equals(kind) ? response(voucher(id, false), true) : response(promotion(id, false));
    }

    @Transactional
    public CampaignResponse save(String kind, Long id, CampaignRequest request) {
        checkKind(kind);
        if (!request.endsAt().isAfter(request.startsAt())) throw error("Thời gian kết thúc phải sau thời gian bắt đầu");
        if ("voucher".equals(kind)) {
            Voucher v = id == null ? new Voucher() : voucher(id, true);
            String code = request.code() == null ? "" : request.code().trim().toUpperCase(Locale.ROOT);
            if (!code.matches("[A-Z0-9_-]{3,50}")) throw error("Mã voucher cần 3–50 ký tự A–Z, 0–9, _ hoặc -");
            if (id != null && v.getUsedCount() > 0 && !code.equals(v.getCode()))
                throw error("Voucher đã dùng hoặc đang giữ lượt không được đổi mã");
            if (vouchers.existsByCodeIgnoreCaseAndIdNot(code, id == null ? -1L : id))
                throw error("Mã voucher đã tồn tại");
            if (!Set.of("FIXED", "PERCENT", "GIFT").contains(request.discountType() == null ? "" : request.discountType()))
                throw error("Loại giảm giá không hợp lệ");
            boolean gift="GIFT".equals(request.discountType());
            if(gift && (!request.redeemable() || request.discountValue()==null || request.discountValue().signum()!=0)) throw error("Ưu đãi gói quà chỉ dùng cho đổi điểm và giá trị giảm bằng 0");
            if(!gift) positive(request.discountValue());
            if(request.redeemable() && (request.pointsRequired()==null || request.pointsRequired()<=0)) throw error("Điểm cần đổi phải là số nguyên dương");
            if(id!=null && v.getUsedCount()>0 && request.redeemable()!=v.isRedeemable()) throw error("Không đổi loại voucher sau khi đã phát sinh lượt sử dụng");
            v.setRedeemable(request.redeemable());v.setPointsRequired(request.redeemable()?request.pointsRequired():null);
            if ("PERCENT".equals(request.discountType()) && request.discountValue().compareTo(new BigDecimal("100")) > 0)
                throw error("Phần trăm giảm không vượt 100");
            if (request.discountValue().stripTrailingZeros().scale() > 0) throw error("Giá trị giảm cần là số nguyên");
            if (request.minOrderAmount() != null && request.minOrderAmount().signum() < 0)
                throw error("Đơn tối thiểu không được âm");
            if (request.maxDiscountAmount() != null) positive(request.maxDiscountAmount());
            if (request.usageLimit() != null && (request.usageLimit() < 1 || request.usageLimit() < v.getUsedCount()))
                throw error("Giới hạn lượt không được thấp hơn số đã dùng và đang giữ");
            v.setName(request.name().trim());
            v.setDescription(request.description());
            v.setCode(code);
            v.setDiscountType(request.discountType());
            v.setDiscountValue(request.discountValue());
            v.setMinOrderAmount(request.minOrderAmount() == null ? BigDecimal.ZERO : request.minOrderAmount());
            v.setDiscountAmount(request.maxDiscountAmount() == null ? BigDecimal.ZERO : request.maxDiscountAmount());
            v.setUsageLimit(request.usageLimit());
            v.setActive(request.enabled());
            v.setStartDate(LocalDateTime.ofInstant(request.startsAt(), ZoneOffset.UTC));
            v.setEndDate(LocalDateTime.ofInstant(request.endsAt(), ZoneOffset.UTC));
            if (id == null) v.setCreatedAt(LocalDateTime.now(orderClock));
            return response(vouchers.saveAndFlush(v), false);
        }
        Promotion p = id == null ? new Promotion() : promotion(id, true);
        positive(request.discountPercent());
        if (request.discountPercent().compareTo(new BigDecimal("100")) > 0 || request.discountPercent().stripTrailingZeros().scale() > 0)
            throw error("Phần trăm giảm cần là số nguyên từ 1–100");
        String mode = request.targetMode() == null ? "SELECTED" : request.targetMode();
        if (!Set.of("SELECTED", "NEW_PRODUCTS").contains(mode)) throw error("Phạm vi sản phẩm không hợp lệ");
        Set<Long> ids = new LinkedHashSet<>(request.productIds() == null ? List.of() : request.productIds());
        if ("SELECTED".equals(mode) && ids.isEmpty()) throw error("Cần chọn ít nhất một sản phẩm");
        var selected = products.findAllById(ids);
        if (selected.size() != ids.size() || selected.stream().anyMatch(product -> !product.isActive() || !Boolean.TRUE.equals(product.getCategory().getIsActive())))
            throw error("Sản phẩm đã bị xóa hoặc ngừng bán");
        p.setName(request.name().trim());
        p.setDescription(request.description());
        p.setDiscountPercent(request.discountPercent());
        p.setStartsAt(request.startsAt());
        p.setEndsAt(request.endsAt());
        p.setActive(request.enabled());
        p.setTargetMode(mode);
        p.getProducts().clear();
        if ("SELECTED".equals(mode)) p.getProducts().addAll(selected);
        if (id == null) p.setCreatedAt(orderClock.instant());
        p.setUpdatedAt(orderClock.instant());
        return response(promotions.saveAndFlush(p));
    }

    @Transactional
    public CampaignResponse state(String kind, Long id, boolean enabled) {
        checkKind(kind);
        if ("voucher".equals(kind)) {
            var v = voucher(id, true);
            v.setActive(enabled);
            return response(v, false);
        }
        var p = promotion(id, true);
        p.setActive(enabled);
        p.setUpdatedAt(orderClock.instant());
        return response(p);
    }

    private Voucher voucher(Long id, boolean lock) {
        var v = (lock ? vouchers.lock(id) : vouchers.findById(id)).orElseThrow(() -> error("Không tìm thấy voucher"));
        if (v.getOwner() != null)
            throw error("Không sửa voucher đã cấp cho khách qua danh mục mẫu ưu đãi");
        return v;
    }

    private Promotion promotion(Long id, boolean lock) {
        return (lock ? promotions.lock(id) : promotions.findById(id)).orElseThrow(() -> error("Không tìm thấy chương trình"));
    }

    private CampaignResponse response(Voucher v, boolean detail) {
        List<CampaignResponse.Usage> usages = detail ? orders.findByVoucherId(v.getId(), org.springframework.data.domain.PageRequest.of(0, 50, org.springframework.data.domain.Sort.by("id").descending())).stream()
                .map(o -> new CampaignResponse.Usage(o.getCode(), o.getRecipientName(), o.getDiscountAmount().subtract(o.getMembershipDiscountAmount()), o.getCreatedAt().toInstant(ZoneOffset.UTC), o.getPaymentStatus(),"FIXED",null)).toList() : List.of();
        if(detail && v.isRedeemable()) {
            usages=vouchers.findBySourceRewardId(v.getId(),org.springframework.data.domain.PageRequest.of(0,50,org.springframework.data.domain.Sort.by("id").descending())).stream()
                .map(issued->new CampaignResponse.Usage(issued.getCode(),issued.getOwner().getFullName(),issued.getDiscountValue(),issued.getCreatedAt().toInstant(ZoneOffset.UTC),
                    issued.getUsedCount()>0?"USED":"AVAILABLE",issued.getDiscountType(),issued.getPointsRequired())).toList();
        }
        String status = status(v.isActive(), v.getStartDate().toInstant(ZoneOffset.UTC), v.getEndDate().toInstant(ZoneOffset.UTC));
        if ("active".equals(status) && v.getUsageLimit() != null && v.getUsedCount() >= v.getUsageLimit())
            status = "exhausted";
        return new CampaignResponse(v.getId(), "voucher", v.getName() == null ? v.getCode() : v.getName(), v.getDescription(),
                v.getStartDate().toInstant(ZoneOffset.UTC), v.getEndDate().toInstant(ZoneOffset.UTC), v.isActive(), status,
                v.getCode(), v.getDiscountType(), v.getDiscountValue(), v.getMinOrderAmount(), v.getDiscountAmount(), v.getUsageLimit(), v.getUsedCount(), null, null, List.of(), usages, v.isRedeemable(), v.getPointsRequired());
    }

    private CampaignResponse response(Promotion p) {
        return new CampaignResponse(p.getId(), "promotion", p.getName(), p.getDescription(), p.getStartsAt(), p.getEndsAt(), p.isActive(), status(p.isActive(), p.getStartsAt(), p.getEndsAt()),
                null, null, null, null, null, null, null, p.getDiscountPercent(), p.getTargetMode(), p.getProducts().stream().map(product -> new CampaignResponse.ProductOption(product.getId(), product.getName())).toList(), List.of(), false, null);
    }

    private String status(boolean active, Instant start, Instant end) {
        var now = orderClock.instant();
        return !now.isBefore(end) ? "expired" : !active ? "paused" : now.isBefore(start) ? "scheduled" : "active";
    }

    private void positive(BigDecimal value) {
        if (value == null || value.signum() <= 0 || value.compareTo(new BigDecimal("9999999999999999")) > 0)
            throw error("Giá trị giảm phải lớn hơn 0 và nằm trong giới hạn");
    }

    private void checkKind(String kind) {
        if (!Set.of("voucher", "promotion").contains(kind)) throw error("Loại chương trình không hợp lệ");
    }

    private BusinessException error(String message) {
        return new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_CAMPAIGN", message);
    }
}
