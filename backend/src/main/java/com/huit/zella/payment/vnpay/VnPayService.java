package com.huit.zella.payment.vnpay;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.*;
import java.math.BigDecimal;
import java.net.URI;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.MultiValueMap;

@Service
@RequiredArgsConstructor
public class VnPayService {
    private static final ZoneId VN_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");
    private final VnPayProperties properties;
    private final OrderService orderService;
    private final OrderRepository orderRepository;
    private final Clock orderClock;

    public void ensureConfigured() {
        if (!properties.isEnabled() || !properties.getTmnCode().matches("[A-Za-z0-9]{8}")
                || properties.getHashSecret().isBlank() || !validPaymentUrl(properties.getPaymentUrl())
                || !validReturnUrl(properties.getReturnUrl())) {
            throw new BusinessException(HttpStatus.SERVICE_UNAVAILABLE, "PAYMENT_NOT_CONFIGURED", "Thanh toán VNPay chưa được cấu hình");
        }
    }

    @Transactional
    public PaymentResponse payment(String code, String token, String clientIp) {
        ensureConfigured();
        var status = orderService.checkoutStatus(code, token);
        Order order = orderRepository.findByIdForUpdate(status.id()).orElseThrow();
        LocalDateTime now = LocalDateTime.now(orderClock);
        if (order.getStatus() != OrderStatus.PENDING || !"PENDING".equals(order.getPaymentStatus())
                || order.getPaymentExpiresAt() == null || !order.getPaymentExpiresAt().isAfter(now)) {
            throw new BusinessException(HttpStatus.CONFLICT, "PAYMENT_CLOSED", "Đơn hàng không còn chờ thanh toán");
        }
        if (order.getPaymentCheckoutUrl() == null) {
            String amount = order.getTotalAmount().movePointRight(2).toBigIntegerExact().toString();
            if (!amount.matches("[1-9][0-9]{0,11}"))
                throw new BusinessException(HttpStatus.CONFLICT, "INVALID_PAYMENT_AMOUNT", "Tổng tiền vượt giới hạn thanh toán VNPay");
            Map<String, String> fields = new TreeMap<>();
            fields.put("vnp_Version", "2.1.0"); fields.put("vnp_Command", "pay");
            fields.put("vnp_TmnCode", properties.getTmnCode()); fields.put("vnp_Amount", amount);
            fields.put("vnp_CurrCode", "VND"); fields.put("vnp_Locale", "vn");
            fields.put("vnp_TxnRef", order.getId().toString()); fields.put("vnp_OrderInfo", "Thanh toan don hang " + order.getId());
            fields.put("vnp_OrderType", "other"); fields.put("vnp_ReturnUrl", properties.getReturnUrl());
            fields.put("vnp_IpAddr", clientIp == null || clientIp.isBlank() ? "127.0.0.1" : clientIp);
            fields.put("vnp_CreateDate", DATE.format(orderClock.instant().atZone(VN_ZONE)));
            fields.put("vnp_ExpireDate", DATE.format(order.getPaymentExpiresAt().atOffset(ZoneOffset.UTC).atZoneSameInstant(VN_ZONE)));
            String url = properties.getPaymentUrl() + "?" + VnPaySignature.query(fields)
                    + "&vnp_SecureHash=" + VnPaySignature.sign(fields, properties.getHashSecret());
            if (url.length() > 1000) throw new BusinessException(HttpStatus.CONFLICT, "INVALID_PAYMENT_URL", "URL thanh toán quá dài");
            order.setPaymentCheckoutUrl(url);
            order.setPaymentMerchantCode(properties.getTmnCode());
            orderRepository.flush();
        }
        if (!properties.getTmnCode().equals(order.getPaymentMerchantCode()))
            throw new BusinessException(HttpStatus.CONFLICT, "PAYMENT_MERCHANT_CHANGED", "Cấu hình thanh toán đã thay đổi. Vui lòng tạo lại đơn");
        return new PaymentResponse(order.getPaymentCheckoutUrl());
    }

    @Transactional
    public Map<String, String> ipn(MultiValueMap<String, String> input) {
        return processCallback(input);
    }

    @Transactional
    public Map<String, String> verifyReturn(String code, String token, MultiValueMap<String, String> input) {
        ensureConfigured();
        var order = orderService.checkoutStatus(code, token);
        if (properties.isIpnRequired()) return result("00", "Awaiting IPN");
        // Browser return confirmation is only available for local sandbox testing.
        URI returnUri = URI.create(properties.getReturnUrl());
        if (!"sandbox.vnpayment.vn".equals(URI.create(properties.getPaymentUrl()).getHost())
                || !Set.of("localhost", "127.0.0.1").contains(returnUri.getHost())) {
            throw new BusinessException(HttpStatus.FORBIDDEN, "LOCAL_PAYMENT_ONLY", "Xác minh qua ReturnURL chỉ dùng cho sandbox local");
        }
        if (!order.id().toString().equals(input.getFirst("vnp_TxnRef"))) return result("01", "Order mismatch");
        return processCallback(input);
    }

    private Map<String, String> processCallback(MultiValueMap<String, String> input) {
        ensureConfigured();
        Map<String, String> fields = VnPaySignature.verify(input, properties.getHashSecret());
        if (fields == null || !properties.getTmnCode().equals(fields.get("vnp_TmnCode"))) return result("97", "Invalid signature");
        String reference = fields.get("vnp_TxnRef");
        if (reference == null || !reference.matches("[1-9][0-9]{0,18}")) return result("01", "Order not found");
        Long orderId;
        try { orderId = Long.valueOf(reference); }
        catch (NumberFormatException ex) { return result("01", "Order not found"); }
        Order order = orderRepository.findByIdForUpdate(orderId).orElse(null);
        if (order == null) return result("01", "Order not found");
        if (order.getPaymentCheckoutUrl() == null || !properties.getTmnCode().equals(order.getPaymentMerchantCode()))
            return result("01", "Payment request not found");
        String rawAmount = fields.get("vnp_Amount");
        if (rawAmount == null || !rawAmount.matches("[0-9]{1,12}")) return result("04", "Invalid amount");
        BigDecimal amount = new BigDecimal(rawAmount).movePointLeft(2);
        if (amount.compareTo(order.getTotalAmount()) != 0) return result("04", "Invalid amount");
        if (!"00".equals(fields.get("vnp_ResponseCode")) || !"00".equals(fields.get("vnp_TransactionStatus")))
            return result("00", "Payment unsuccessful; order awaits expiry");
        String transaction = fields.get("vnp_TransactionNo");
        if (transaction == null || !transaction.matches("[1-9][0-9]{0,19}")) return result("99", "Invalid transaction");
        if (order.getOnlineTransactionId() != null) return result("02", "Order already confirmed");
        orderService.recordOnlinePayment(order.getId(), amount, "VNPAY-" + transaction);
        return result("00", "Confirm success");
    }

    static Map<String, String> result(String code, String message) { return Map.of("RspCode", code, "Message", message); }

    static boolean validPaymentUrl(String value) {
        try {
            URI uri = URI.create(value);
            return "https".equals(uri.getScheme()) && Set.of("sandbox.vnpayment.vn", "pay.vnpay.vn").contains(uri.getHost())
                    && "/paymentv2/vpcpay.html".equals(uri.getPath()) && uri.getUserInfo() == null
                    && uri.getQuery() == null && uri.getFragment() == null && (uri.getPort() == -1 || uri.getPort() == 443);
        } catch (IllegalArgumentException | NullPointerException ex) { return false; }
    }

    private static boolean validReturnUrl(String value) {
        try {
            URI uri = URI.create(value);
            return value.length() <= 255 && uri.getHost() != null && uri.getUserInfo() == null && uri.getFragment() == null
                    && ("https".equals(uri.getScheme()) || ("http".equals(uri.getScheme())
                    && Set.of("localhost", "127.0.0.1").contains(uri.getHost())));
        } catch (IllegalArgumentException | NullPointerException ex) { return false; }
    }
    public record PaymentResponse(String checkoutUrl) {}
}
