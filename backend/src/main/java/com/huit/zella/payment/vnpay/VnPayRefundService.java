package com.huit.zella.payment.vnpay;

import com.huit.zella.auth.UserRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.*;
import com.huit.zella.orderreturn.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.TransactionDefinition;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;
import java.math.BigDecimal;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.time.format.*;
import java.util.*;
import java.util.function.Supplier;

@Service @RequiredArgsConstructor
public class VnPayRefundService {
    private final PaymentRefundRepository refunds;
    private final OrderService orders;
    private final ReturnRepository returns;
    private final ReturnService returnService;
    private final UserRepository users;
    private final VnPayGateway gateway;
    private final VnPayProperties properties;
    private final Clock orderClock;
    private final PlatformTransactionManager transactionManager;

    public record RefundView(Long id, Long orderId, Long returnId, String requestId, BigDecimal amount,
            String state, String responseCode, String gatewayStatus, String refundTransactionNo) {
        static RefundView from(PaymentRefund r) {
            return new RefundView(r.getId(), r.getOrderId(), r.getReturnId(), r.getRequestId(), r.getAmount(),
                r.getState(), r.getResponseCode(), r.getGatewayStatus(), r.getRefundTransactionNo());
        }
    }
    private record Prepared(PaymentRefund refund, boolean send) {}

    // Commit the durable attempt BEFORE making any network request. A timeout/crash must never allow a blind resend.
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public RefundView submit(Long orderId, Long returnId, String note, Long actorId) {
        gateway.ensureConfigured();
        Prepared prepared = transaction(() -> prepare(orderId, returnId, note, actorId));
        PaymentRefund refund = prepared.refund();
        if (!prepared.send()) return RefundView.from(refund);
        Map<String, String> result;
        try { result = gateway.refund(refund, orderClock.instant()); }
        catch (RuntimeException ex) {
            return transaction(() -> {
                orders.lock(refund.getOrderId());
                PaymentRefund saved = refunds.findById(refund.getId()).orElseThrow();
                saved.setState("UNKNOWN"); saved.setUpdatedAt(LocalDateTime.now(orderClock));
                return RefundView.from(saved);
            });
        }
        return transaction(() -> apply(refund.getId(), result, false));
    }

    @Transactional(readOnly = true)
    public List<RefundView> list(Long orderId) {
        orders.get(orderId);
        return refunds.findByOrderIdOrderByIdDesc(orderId).stream().map(RefundView::from).toList();
    }

    /** Read-only query to the gateway; never sends a second refund request. */
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    public RefundView reconcile(Long id) {
        PaymentRefund saved = transaction(() -> refunds.findById(id)
            .orElseThrow(() -> error("REFUND_NOT_FOUND", "Không tìm thấy yêu cầu hoàn tiền")));
        if (Set.of("SUCCEEDED", "REJECTED").contains(saved.getState())) return RefundView.from(saved);
        Map<String, String> result;
        try { result = gateway.query(saved, orderClock.instant()); }
        catch (RuntimeException ex) { throw new BusinessException(HttpStatus.BAD_GATEWAY, "REFUND_QUERY_UNAVAILABLE",
            "Chưa đối soát được với VNPay. Không gửi lại yêu cầu hoàn tiền; hãy thử đối soát sau"); }
        return transaction(() -> apply(id, result, true));
    }

    private Prepared prepare(Long orderId, Long returnId, String note, Long actorId) {
        if (returnId != null) orderId = returns.findOrderId(returnId)
            .orElseThrow(() -> error("RETURN_NOT_FOUND", "Không tìm thấy phiếu trả"));
        Order order = orders.lock(orderId);
        String target = returnId == null ? "ORDER-" + orderId : "RETURN-" + returnId;
        var previous = refunds.findFirstByTargetOrderByIdDesc(target);
        if (previous.isPresent() && !"REJECTED".equals(previous.get().getState())) return new Prepared(previous.get(), false);
        if (order.getOnlineTransactionId() == null || !order.getOnlineTransactionId().matches("VNPAY-[1-9][0-9]{0,14}")
                || !properties.getTmnCode().equals(order.getPaymentMerchantCode()))
            throw error("INVALID_VNPAY_TRANSACTION", "Đơn không có giao dịch VNPay hợp lệ của merchant hiện tại");
        BigDecimal amount;
        if (returnId == null) {
            if (order.getStatus() != OrderStatus.CANCELLED || !"REFUND_PENDING".equals(order.getPaymentStatus()))
                throw error("INVALID_REFUND_ORDER", "Chỉ hoàn toàn bộ cho đơn đã hủy đang chờ hoàn tiền");
            amount = order.getTotalAmount();
        } else {
            ReturnRequest document = returns.findByIdForUpdate(returnId).orElseThrow();
            if (document.getStatus() != ReturnStatus.RECEIVED
                    || !Set.of("PAID", "REFUND_PENDING").contains(order.getPaymentStatus()))
                throw error("INVALID_REFUND_RETURN", "Chỉ hoàn tiền sau khi đã nhận và kiểm tra hàng trả");
            amount = document.getRefundAmount();
        }
        if (amount.signum() <= 0 || !amount.movePointRight(2).toBigIntegerExact().toString().matches("[1-9][0-9]{0,11}"))
            throw error("INVALID_REFUND_AMOUNT", "Số tiền hoàn không hợp lệ");
        var attempts = refunds.findByOrderIdOrderByIdDesc(orderId);
        if (attempts.stream().anyMatch(r -> !Set.of("SUCCEEDED", "REJECTED").contains(r.getState())))
            throw error("REFUND_IN_PROGRESS", "Đơn có khoản hoàn chưa rõ kết quả. Cần đối soát trước khi hoàn tiếp");
        BigDecimal paidBack = attempts.stream().filter(r -> "SUCCEEDED".equals(r.getState()))
            .map(PaymentRefund::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        if (paidBack.add(amount).compareTo(order.getTotalAmount()) > 0)
            throw error("REFUND_EXCEEDS_PAYMENT", "Tổng tiền hoàn vượt số tiền đã thanh toán");
        PaymentRefund refund = new PaymentRefund();
        refund.setOrderId(orderId); refund.setReturnId(returnId); refund.setTarget(target);
        refund.setRequestId(UUID.randomUUID().toString().replace("-", "")); refund.setAmount(amount);
        refund.setState("PROCESSING"); refund.setMerchantCode(properties.getTmnCode());
        refund.setTransactionType(paidBack.signum() == 0 && amount.compareTo(order.getTotalAmount()) == 0 ? "02" : "03");
        refund.setTransactionDate(transactionDate(order));
        refund.setTransactionNo(order.getOnlineTransactionId().substring(6));
        refund.setNote(note.trim()); refund.setActorId(actorId);
        refund.setCreatedAt(LocalDateTime.now(orderClock)); refund.setUpdatedAt(refund.getCreatedAt());
        return new Prepared(refunds.saveAndFlush(refund), true);
    }

    private RefundView apply(Long id, Map<String, String> result, boolean query) {
        Long orderId = refunds.findOrderIdById(id).orElseThrow();
        Order order = orders.lock(orderId);
        PaymentRefund refund = refunds.findById(id).orElseThrow();
        if (Set.of("SUCCEEDED", "REJECTED").contains(refund.getState())) return RefundView.from(refund);
        String code = result.get("vnp_ResponseCode"), state = result.get("vnp_TransactionStatus");
        String transactionNo = result.get("vnp_TransactionNo");
        boolean matches = VnPayGateway.minorAmount(refund).equals(result.get("vnp_Amount"))
            && refund.getTransactionType().equals(result.get("vnp_TransactionType"))
            && transactionNo != null && transactionNo.matches("[1-9][0-9]{0,14}")
            && !transactionNo.equals(refund.getTransactionNo());
        final Long currentId = refund.getId();
        if (matches && refunds.findByOrderIdOrderByIdDesc(orderId).stream().anyMatch(r -> !r.getId().equals(currentId)
                && transactionNo.equals(r.getRefundTransactionNo()))) matches = false;
        if (query) {
            // The original query may describe an older partial refund. Only reconcile an already identified refund.
            matches = matches && transactionNo.equals(refund.getRefundTransactionNo());
            if (!matches || !"00".equals(code)) return RefundView.from(refund);
        }
        if (code == null || !code.matches("[0-9]{2}") || (state != null && !state.matches("[0-9]{2}")))
            throw error("INVALID_GATEWAY_RESULT", "Kết quả hoàn tiền VNPay không hợp lệ, cần đối soát");
        refund.setResponseCode(code); refund.setGatewayStatus(state);
        if (matches && "00".equals(code)) refund.setRefundTransactionNo(transactionNo);
        if (matches && "00".equals(code) && "00".equals(state)) {
            if (refund.getReturnId() == null) {
                if (order.getStatus() != OrderStatus.CANCELLED || !"REFUND_PENDING".equals(order.getPaymentStatus()))
                    throw error("INVALID_REFUND_ORDER", "Trạng thái đơn thay đổi, cần đối soát khoản hoàn");
                order.setPaymentStatus("REFUNDED"); order.setUpdatedAt(LocalDateTime.now(orderClock));
                OrderHistory history = new OrderHistory(); history.setOrder(order);
                history.setOldStatus(order.getStatus().name()); history.setNewStatus(order.getStatus().name());
                history.setNote("VNPay hoàn tiền: " + refund.getRequestId());
                history.setCreatedBy(users.getReferenceById(refund.getActorId())); history.setCreatedAt(LocalDateTime.now(orderClock));
                order.getHistories().add(history);
            } else returnService.completeVnPay(refund.getReturnId(), refund.getNote(), refund.getActorId());
            refund.setState("SUCCEEDED");
        } else if ((matches && "00".equals(code) && "09".equals(state))
                || (!query && Set.of("02", "03", "91", "95", "97").contains(code))) refund.setState("REJECTED");
        else refund.setState("PENDING");
        refund.setUpdatedAt(LocalDateTime.now(orderClock));
        return RefundView.from(refund);
    }

    static String transactionDate(Order order) {
        try {
            String query = URI.create(order.getPaymentCheckoutUrl()).getRawQuery();
            List<String> values = Arrays.stream(query.split("&")).filter(s -> s.startsWith("vnp_CreateDate="))
                .map(s -> URLDecoder.decode(s.substring("vnp_CreateDate=".length()), StandardCharsets.UTF_8)).toList();
            if (values.size() != 1 || !values.getFirst().matches("[0-9]{14}")) throw new IllegalArgumentException();
            LocalDateTime.parse(values.getFirst(), DateTimeFormatter.ofPattern("uuuuMMddHHmmss").withResolverStyle(ResolverStyle.STRICT));
            return values.getFirst();
        } catch (RuntimeException ex) { throw error("PAYMENT_DATE_MISSING", "Thiếu thời điểm tạo giao dịch VNPay gốc, không tự suy đoán ngày hoàn tiền"); }
    }

    private <T> T transaction(Supplier<T> work) {
        TransactionTemplate tx = new TransactionTemplate(transactionManager);
        tx.setPropagationBehavior(TransactionDefinition.PROPAGATION_REQUIRES_NEW);
        return tx.execute(status -> work.get());
    }
    private static BusinessException error(String code, String message) {
        return new BusinessException(HttpStatus.CONFLICT, code, message);
    }
}
