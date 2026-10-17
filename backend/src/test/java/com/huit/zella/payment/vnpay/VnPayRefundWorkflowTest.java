package com.huit.zella.payment.vnpay;

import com.huit.zella.auth.User;
import com.huit.zella.order.Order;
import com.huit.zella.order.OrderStatus;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.math.BigDecimal;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

@SpringBootTest(properties = {"app.order.expiration.enabled=false", "app.payment.vnpay.tmn-code=TEST1234"})
class VnPayRefundWorkflowTest {
    @Autowired VnPayRefundService service;
    @Autowired PaymentRefundRepository repository;
    @Autowired PlatformTransactionManager manager;
    @PersistenceContext EntityManager em;
    @MockitoBean VnPayGateway gateway;
    private Long orderId, actorId;

    @BeforeEach void setup() {
        new TransactionTemplate(manager).executeWithoutResult(status -> {
            User actor = new User(); String token = UUID.randomUUID().toString().substring(0, 12);
            actor.setUserName("refund-" + token); actor.setEmail(token + "@refund.test"); actor.setPasswordHash("test-only");
            em.persist(actor); actorId = actor.getId();
            Order order = new Order(); order.setCode("ORD-" + token.toUpperCase(Locale.ROOT));
            order.setRecipientName("Kiểm thử hoàn tiền"); order.setRecipientPhone("0900000000"); order.setAddress("Test");
            order.setCustomer(actor); order.setPaymentMethod("ONLINE"); order.setPaymentStatus("REFUND_PENDING");
            order.setStatus(OrderStatus.CANCELLED); order.setTotalAmount(new BigDecimal("100000"));
            order.setSubtotal(order.getTotalAmount()); order.setOnlineTransactionId("VNPAY-12345"); order.setPaymentMerchantCode("TEST1234");
            order.setPaymentCheckoutUrl("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?vnp_CreateDate=20261015140000");
            em.persist(order); em.flush(); orderId = order.getId();
        });
    }
    @AfterEach void cleanup() {
        new TransactionTemplate(manager).executeWithoutResult(status -> {
            if (orderId != null) {
                em.createQuery("delete from PaymentRefund r where r.orderId=:id").setParameter("id", orderId).executeUpdate();
                Order order = em.find(Order.class, orderId); if (order != null) em.remove(order);
                em.flush();
            }
            if (actorId != null) { User actor = em.find(User.class, actorId); if (actor != null) em.remove(actor); }
        });
    }
    private Map<String, String> success(PaymentRefund refund) {
        return Map.of("vnp_ResponseCode", "00", "vnp_TransactionStatus", "00", "vnp_Amount", "10000000",
            "vnp_TransactionType", "02", "vnp_TransactionNo", "98765");
    }
    @Test void attemptIsCommittedAndVisibleBeforeNetworkAndCompletionIsAtomic() {
        doAnswer(call -> {
            assertFalse(TransactionSynchronizationManager.isActualTransactionActive());
            PaymentRefund refund = call.getArgument(0);
            assertEquals("PROCESSING", repository.findById(refund.getId()).orElseThrow().getState());
            return success(refund);
        }).when(gateway).refund(any(), any());
        var result = service.submit(orderId, null, "Hoàn đơn đã hủy", actorId);
        assertEquals("SUCCEEDED", result.state());
        new TransactionTemplate(manager).executeWithoutResult(status -> {
            assertEquals("REFUNDED", em.find(Order.class, orderId).getPaymentStatus());
            assertEquals(1, em.find(Order.class, orderId).getHistories().size());
        });
        assertEquals("SUCCEEDED", service.submit(orderId, null, "Gửi lại", actorId).state());
        verify(gateway, times(1)).refund(any(), any());
    }
    @Test void timeoutSurvivesNewTransactionsAndDuplicateDoesNotSendAgain() {
        doThrow(new IllegalStateException("timeout")).when(gateway).refund(any(), any());
        var result = service.submit(orderId, null, "Hoàn đơn", actorId);
        assertEquals("UNKNOWN", result.state());
        assertEquals("UNKNOWN", repository.findById(result.id()).orElseThrow().getState());
        assertEquals("UNKNOWN", service.submit(orderId, null, "Gửi lại", actorId).state());
        verify(gateway, times(1)).refund(any(), any());
    }
    @Test void concurrentSubmissionReadsCommittedAttemptInsteadOfRefundingTwice() throws Exception {
        CountDownLatch inGateway = new CountDownLatch(1), release = new CountDownLatch(1);
        doAnswer(call -> {
            inGateway.countDown(); if (!release.await(15, TimeUnit.SECONDS)) throw new IllegalStateException("test timeout");
            return success(call.getArgument(0));
        }).when(gateway).refund(any(), any());
        try (var executor = Executors.newVirtualThreadPerTaskExecutor()) {
            var first = executor.submit(() -> service.submit(orderId, null, "Hoàn đơn", actorId));
            try {
                assertTrue(inGateway.await(10, TimeUnit.SECONDS));
                var duplicate = service.submit(orderId, null, "Lặp đồng thời", actorId);
                assertEquals("PROCESSING", duplicate.state());
            } finally { release.countDown(); }
            assertEquals("SUCCEEDED", first.get(10, TimeUnit.SECONDS).state());
        }
        assertEquals(1, repository.findByOrderIdOrderByIdDesc(orderId).size());
        verify(gateway, times(1)).refund(any(), any());
    }
}
