package com.huit.zella.payment.vnpay;

import com.huit.zella.auth.UserRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.*;
import com.huit.zella.orderreturn.*;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import org.springframework.transaction.*;
import org.springframework.transaction.support.SimpleTransactionStatus;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class VnPayRefundServiceTest {
    private final PaymentRefundRepository repository = mock(PaymentRefundRepository.class);
    private final OrderService orders = mock(OrderService.class);
    private final ReturnRepository returns = mock(ReturnRepository.class);
    private final ReturnService returnService = mock(ReturnService.class);
    private final VnPayGateway gateway = mock(VnPayGateway.class);
    private final PlatformTransactionManager manager = mock(PlatformTransactionManager.class);
    private final VnPayProperties config = new VnPayProperties();
    private final Order order = new Order();
    private final List<PaymentRefund> attempts = new ArrayList<>();
    private final VnPayRefundService service = new VnPayRefundService(repository, orders, returns, returnService,
        mock(UserRepository.class), gateway, config, Clock.fixed(Instant.parse("2026-10-15T08:00:00Z"), ZoneOffset.UTC), manager);

    @BeforeEach void setup() {
        config.setTmnCode("TEST1234"); order.setId(1L); order.setStatus(OrderStatus.CANCELLED);
        order.setPaymentStatus("REFUND_PENDING"); order.setTotalAmount(new BigDecimal("100000"));
        order.setPaymentMerchantCode("TEST1234"); order.setOnlineTransactionId("VNPAY-12345");
        order.setPaymentCheckoutUrl("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_CreateDate=20261015140000");
        when(orders.lock(1L)).thenReturn(order);
        when(manager.getTransaction(any())).thenAnswer(call -> new SimpleTransactionStatus());
        when(repository.findByOrderIdOrderByIdDesc(1L)).thenReturn(attempts);
        when(repository.findFirstByTargetOrderByIdDesc(anyString())).thenAnswer(call -> attempts.stream()
            .filter(r -> r.getTarget().equals(call.getArgument(0))).reduce((a,b) -> b));
        when(repository.saveAndFlush(any())).thenAnswer(call -> {
            PaymentRefund refund = call.getArgument(0); refund.setId((long) attempts.size() + 1); attempts.add(refund); return refund;
        });
        when(repository.findById(anyLong())).thenAnswer(call -> attempts.stream().filter(r -> r.getId().equals(call.getArgument(0))).findFirst());
        when(repository.findOrderIdById(anyLong())).thenReturn(Optional.of(1L));
        doAnswer(call -> response(call.getArgument(0), "00", "00")).when(gateway).refund(any(), any());
    }
    private Map<String, String> response(PaymentRefund refund, String code, String status) {
        return Map.of("vnp_ResponseCode", code, "vnp_TransactionStatus", status, "vnp_TransactionNo", "98765",
            "vnp_Amount", VnPayGateway.minorAmount(refund), "vnp_TransactionType", refund.getTransactionType());
    }
    @Test void commitsAttemptBeforeGatewayCallAndConfirmsOnlyOnce() {
        assertEquals("SUCCEEDED", service.submit(1L, null, "Hủy đơn", 9L).state());
        assertEquals("REFUNDED", order.getPaymentStatus());
        assertEquals("SUCCEEDED", service.submit(1L, null, "Lặp yêu cầu", 9L).state());
        var sequence = inOrder(repository, manager, gateway);
        sequence.verify(repository).saveAndFlush(any()); sequence.verify(manager).commit(any()); sequence.verify(gateway).refund(any(), any());
        verify(gateway, times(1)).refund(any(), any()); assertEquals(1, order.getHistories().size());
    }
    @Test void timeoutIsDurableUnknownAndDuplicateNeverResends() {
        doThrow(new IllegalStateException("timeout")).when(gateway).refund(any(), any());
        assertEquals("UNKNOWN", service.submit(1L, null, "Hủy đơn", 9L).state());
        assertEquals("UNKNOWN", service.submit(1L, null, "Thử lại", 9L).state());
        assertEquals("REFUND_PENDING", order.getPaymentStatus()); verify(gateway, times(1)).refund(any(), any());
    }
    @Test void acceptedPendingIsNotCompletedAndCanBeReconciledByExactRefundTransaction() {
        doAnswer(call -> response(call.getArgument(0), "00", "05")).when(gateway).refund(any(), any());
        var refund = service.submit(1L, null, "Hủy đơn", 9L);
        assertEquals("PENDING", refund.state()); assertEquals("REFUND_PENDING", order.getPaymentStatus());
        when(gateway.query(any(), any())).thenAnswer(call -> response(call.getArgument(0), "00", "00"));
        assertEquals("SUCCEEDED", service.reconcile(refund.id()).state());
        verify(gateway, times(1)).refund(any(), any());
    }
    @Test void unknownCannotBeMatchedToAnUnidentifiedOlderRefund() {
        doThrow(new IllegalStateException("timeout")).when(gateway).refund(any(), any());
        var refund = service.submit(1L, null, "Hủy đơn", 9L);
        when(gateway.query(any(), any())).thenAnswer(call -> response(call.getArgument(0), "00", "00"));
        assertEquals("UNKNOWN", service.reconcile(refund.id()).state()); assertEquals("REFUND_PENDING", order.getPaymentStatus());
    }
    @Test void signedRejectionAllowsNewAttemptWithDifferentRequestId() {
        doAnswer(call -> response(call.getArgument(0), "95", "09")).when(gateway).refund(any(), any());
        var first = service.submit(1L, null, "Hủy đơn", 9L);
        assertEquals("REJECTED", first.state());
        doAnswer(call -> response(call.getArgument(0), "00", "00")).when(gateway).refund(any(), any());
        var second = service.submit(1L, null, "Đã sửa cấu hình", 9L);
        assertNotEquals(first.requestId(), second.requestId()); assertEquals("SUCCEEDED", second.state());
    }
    @Test void wrongMerchantOrMissingOriginalDateNeverSendsRefund() {
        order.setPaymentMerchantCode("OTHER123");
        assertEquals("INVALID_VNPAY_TRANSACTION", assertThrows(BusinessException.class, () -> service.submit(1L, null, "Hoàn", 9L)).getCode());
        order.setPaymentMerchantCode("TEST1234"); order.setPaymentCheckoutUrl("https://example.com");
        assertEquals("PAYMENT_DATE_MISSING", assertThrows(BusinessException.class, () -> service.submit(1L, null, "Hoàn", 9L)).getCode());
        verify(gateway, never()).refund(any(), any());
    }
    @Test void cannotRefundBeforeCancellation() {
        order.setStatus(OrderStatus.CONFIRMED);
        assertEquals("INVALID_REFUND_ORDER", assertThrows(BusinessException.class, () -> service.submit(1L, null, "Hoàn", 9L)).getCode());
        verify(gateway, never()).refund(any(), any());
    }
    private ReturnRequest receivedReturn() {
        order.setStatus(OrderStatus.DELIVERED); order.setPaymentStatus("PAID");
        var document = new ReturnRequest(); document.setId(10L); document.setOrder(order);
        document.setStatus(ReturnStatus.RECEIVED); document.setRefundAmount(new BigDecimal("40000"));
        when(returns.findOrderId(10L)).thenReturn(Optional.of(1L));
        when(returns.findByIdForUpdate(10L)).thenReturn(Optional.of(document)); return document;
    }
    @Test void partialReturnUsesServerAmountAndCompletesOnlyAfterConfirmation() {
        receivedReturn(); var refund = service.submit(null, 10L, "Trả một phần", 9L);
        assertEquals(new BigDecimal("40000"), refund.amount()); assertEquals("03", attempts.getFirst().getTransactionType());
        assertEquals("SUCCEEDED", refund.state()); verify(returnService).completeVnPay(10L, "Trả một phần", 9L);
    }
    @Test void unreceivedReturnAndAmountsAbovePaymentAreRejected() {
        var document = receivedReturn(); document.setStatus(ReturnStatus.APPROVED);
        assertThrows(BusinessException.class, () -> service.submit(null, 10L, "Hoàn", 9L));
        document.setStatus(ReturnStatus.RECEIVED); document.setRefundAmount(new BigDecimal("100001"));
        assertEquals("REFUND_EXCEEDS_PAYMENT", assertThrows(BusinessException.class, () -> service.submit(null, 10L, "Hoàn", 9L)).getCode());
        verify(gateway, never()).refund(any(), any());
    }
    @Test void concurrentDifferentReturnBlockedWhilePreviousRefundUncertain() {
        receivedReturn(); doThrow(new IllegalStateException("timeout")).when(gateway).refund(any(), any());
        service.submit(null, 10L, "Trả một phần", 9L);
        when(returns.findOrderId(11L)).thenReturn(Optional.of(1L));
        var next = new ReturnRequest(); next.setStatus(ReturnStatus.RECEIVED); next.setRefundAmount(BigDecimal.TEN);
        when(returns.findByIdForUpdate(11L)).thenReturn(Optional.of(next));
        assertEquals("REFUND_IN_PROGRESS", assertThrows(BusinessException.class, () -> service.submit(null, 11L, "Hoàn tiếp", 9L)).getCode());
        verify(gateway, times(1)).refund(any(), any());
    }
    @Test void queryOriginalPaymentNeverConfirmsRefund() {
        doAnswer(call -> response(call.getArgument(0), "00", "05")).when(gateway).refund(any(), any());
        var refund = service.submit(1L, null, "Hoàn", 9L);
        when(gateway.query(any(), any())).thenReturn(Map.of("vnp_ResponseCode", "00", "vnp_TransactionStatus", "00",
            "vnp_TransactionNo", "12345", "vnp_Amount", "10000000", "vnp_TransactionType", "01"));
        assertEquals("PENDING", service.reconcile(refund.id()).state()); assertEquals("REFUND_PENDING", order.getPaymentStatus());
    }
}
