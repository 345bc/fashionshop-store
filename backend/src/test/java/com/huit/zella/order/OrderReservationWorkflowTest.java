package com.huit.zella.order;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.inventory.*;
import com.huit.zella.orderreturn.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.*;
import org.springframework.data.domain.PageRequest;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.http.MediaType;
import com.jayway.jsonpath.JsonPath;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import org.springframework.security.test.context.support.WithMockUser;

@SpringBootTest(properties = {"app.order.expiration.enabled=false", "app.order.payment-simulation.enabled=true"})
@Import(OrderReservationWorkflowTest.TimeConfig.class)
@Transactional
@AutoConfigureMockMvc
class OrderReservationWorkflowTest extends WarehouseFixture {
    static class MutableClock extends Clock {
        Instant value = Instant.parse("2026-10-01T00:00:00Z");
        @Override public ZoneId getZone() { return ZoneOffset.UTC; }
        @Override public Clock withZone(ZoneId zone) { return this; }
        @Override public Instant instant() { return value; }
        void advanceSeconds(long seconds) { value = value.plusSeconds(seconds); }
    }
    @TestConfiguration
    static class TimeConfig {
        @Bean @Primary MutableClock testClock() { return new MutableClock(); }
    }
    @Autowired OrderService orders;
    @Autowired OrderRepository orderRepository;
    @Autowired InventoryService inventory;
    @Autowired ReturnService returns;
    @Autowired MutableClock clock;
    @Autowired MockMvc mockMvc;
    @Autowired OrderPaymentSimulationService simulation;

    @BeforeEach
    void resetTime() { clock.value = Instant.parse("2026-10-01T00:00:00Z"); }
    private OrderResponse create() {
        return orders.create(new CreateOrderRequest(null, "Khách vãng lai", "0900000000", "TP.HCM", null,
            BigDecimal.ZERO, "ONLINE", List.of(new CreateOrderRequest.Item(variant.getId(), 3))), null);
    }
    private void pay(OrderResponse order, String transaction) {
        orders.recordOnlinePayment(order.id(), order.totalAmount(), transaction);
    }
    @Test
    void guestOrderReservesForExactlyFiveMinutesAndExpiryOnlyReleasesItsOwnQuantity() {
        OrderResponse order = create();
        assertNull(order.customerUserId());
        assertEquals("PENDING", order.status());
        assertEquals(5, variant.getReservedQuantity());
        assertEquals(clock.instant().plusSeconds(300), order.paymentExpiresAt().toInstant());
        clock.advanceSeconds(299);
        assertFalse(orders.expire(order.id()));
        clock.advanceSeconds(1);
        assertTrue(orderRepository.findExpiredOrderIds(LocalDateTime.now(clock), PageRequest.of(0, 100)).contains(order.id()));
        assertTrue(orders.expire(order.id()));
        assertEquals(10, variant.getStockQuantity());
        assertEquals(2, variant.getReservedQuantity());
        assertEquals("CANCELLED", orders.get(order.id()).status());
        assertEquals("EXPIRED", orders.get(order.id()).paymentStatus());
        assertEquals("Hệ thống", orders.get(order.id()).histories().getLast().createdBy());
        assertFalse(orders.expire(order.id()));
        assertEquals(2, inventory.history(variant.getId(), org.springframework.data.domain.PageRequest.of(0, 100, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "id"))).getContent().size());
    }
    @Test
    void paidBeforeDeadlineAutomaticallyConfirmsAndRepeatedNotificationIsIdempotent() {
        OrderResponse order = create();
        clock.advanceSeconds(299);
        pay(order, "TX-A");
        assertEquals("CONFIRMED", orders.get(order.id()).status());
        assertEquals("PAID", orders.get(order.id()).paymentStatus());
        int history = orders.get(order.id()).histories().size();
        pay(order, "TX-A");
        assertEquals(history, orders.get(order.id()).histories().size());
        clock.advanceSeconds(2);
        assertFalse(orders.expire(order.id()));
        assertEquals(5, variant.getReservedQuantity());
        orders.ship(order.id(), actor.getId());
        assertEquals(7, variant.getStockQuantity());
        assertEquals(2, variant.getReservedQuantity());
    }
    @Test
    void paymentAtDeadlineCancelsAndRequiresRefundWithoutReacquiringStock() {
        OrderResponse order = create();
        clock.advanceSeconds(300);
        pay(order, "TX-LATE");
        assertEquals("CANCELLED", orders.get(order.id()).status());
        assertEquals("REFUND_PENDING", orders.get(order.id()).paymentStatus());
        assertEquals(2, variant.getReservedQuantity());
        assertEquals(10, variant.getStockQuantity());
        pay(order, "TX-LATE");
        assertEquals(2, inventory.history(variant.getId(), org.springframework.data.domain.PageRequest.of(0, 100, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "id"))).getContent().size());
    }
    @Test
    void paymentAfterSchedulerHasCancelledOrderDoesNotResurrectIt() {
        OrderResponse order = create();
        clock.advanceSeconds(301);
        assertTrue(orders.expire(order.id()));
        pay(order, "TX-AFTER-EXPIRY");
        assertEquals("CANCELLED", orders.get(order.id()).status());
        assertEquals("REFUND_PENDING", orders.get(order.id()).paymentStatus());
        assertEquals(2, variant.getReservedQuantity());
    }
    @Test
    void invalidAmountAndReusedTransactionDoNotConfirmAnotherOrder() {
        OrderResponse first = create();
        assertThrows(BusinessException.class, () -> orders.recordOnlinePayment(first.id(), BigDecimal.ONE, "TX-WRONG"));
        assertEquals("PENDING", orders.get(first.id()).status());
        pay(first, "TX-UNIQUE");
        OrderResponse second = create();
        assertThrows(BusinessException.class, () -> pay(second, "TX-UNIQUE"));
        assertEquals("PENDING", orders.get(second.id()).status());
    }
    @Test
    void guestCheckoutCalculatesFeeAndProtectsStatusWithToken() {
        CheckoutOrderResponse order = orders.createCheckout(new CreateCheckoutOrderRequest(
            "Guest", "0900000000", "TP.HCM", null, "STANDARD",
            List.of(new CreateOrderRequest.Item(variant.getId(), 1))), null);
        assertEquals(new BigDecimal("30300.00"), order.totalAmount().setScale(2));
        assertNull(orders.get(order.id()).customerUserId());
        assertEquals(order.code(), orders.checkoutStatus(order.code(), order.checkoutToken()).code());
        assertNull(orders.checkoutStatus(order.code(), order.checkoutToken()).checkoutToken());
        assertThrows(BusinessException.class, () -> orders.checkoutStatus(order.code(), "wrong-token"));
    }
    @Test
    void guestCanReturnPaidOrderWithoutCreatingAnAccount() {
        OrderResponse order = create();
        pay(order, "TX-GUEST");
        orders.ship(order.id(), actor.getId());
        orders.deliver(order.id(), actor.getId());
        ReturnResponse document = returns.create(new CreateReturnRequest(order.id(), "Trả hàng khách vãng lai",
            List.of(new CreateReturnRequest.Item(order.items().getFirst().id(), 1))), actor.getId());
        returns.approve(document.id(), actor.getId());
        returns.receive(document.id(), new ReceiveReturnRequest(List.of(
            new ReceiveReturnRequest.Item(document.items().getFirst().id(), "INTACT"))), actor.getId());
        assertEquals(8, variant.getStockQuantity());
    }
    @Test
    void codIsRejectedEvenIfCalledDirectlyFromJava() {
        assertEquals("ONLINE_PAYMENT_ONLY", assertThrows(BusinessException.class, () -> orders.create(
            new CreateOrderRequest(null, "Guest", "0900000000", "TP.HCM", null, BigDecimal.ZERO, "COD",
                List.of(new CreateOrderRequest.Item(variant.getId(), 1))), null)).getCode());
    }

    @Test
    void schedulerCancelsDueOrderAndDoesNotReleaseItTwice() {
        OrderResponse order = create();
        clock.advanceSeconds(300);
        OrderExpirationScheduler scheduler = new OrderExpirationScheduler(orderRepository, orders, clock);
        scheduler.expireOrders();
        scheduler.expireOrders();
        assertEquals("CANCELLED", orders.get(order.id()).status());
        assertEquals(2, variant.getReservedQuantity());
    }

    @Test
    void guestHttpCheckoutWorksWithoutAuthenticationAndDoesNotExposeStatusWithoutToken() throws Exception {
        String body = """
            {"recipientName":"Guest","recipientPhone":"0900000000","address":"TP.HCM",
             "shippingMethod":"STANDARD","items":[{"variantId":%d,"quantity":1}]}
            """.formatted(variant.getId());
        String response = mockMvc.perform(post("/api/v1/checkout/orders").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.data.status").value("PENDING"))
            .andExpect(jsonPath("$.data.totalAmount").value(30300))
            .andReturn().getResponse().getContentAsString();
        String code = JsonPath.read(response, "$.data.code");
        String token = JsonPath.read(response, "$.data.checkoutToken");
        mockMvc.perform(get("/api/v1/checkout/orders/" + code).header("X-Checkout-Token", token))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("PENDING"));
        mockMvc.perform(get("/api/v1/checkout/orders/" + code).header("X-Checkout-Token", "wrong"))
            .andExpect(status().isConflict());
        mockMvc.perform(post("/api/v1/order").with(csrf()).contentType(MediaType.APPLICATION_JSON).content("{}"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void temporaryConfirmationApiUsesOnlineWorkflowAndIsIdempotent() throws Exception {
        OrderResponse order = create();
        mockMvc.perform(get("/api/v1/order-test/enabled")).andExpect(status().isOk())
            .andExpect(jsonPath("$.data").value(true));
        mockMvc.perform(post("/api/v1/order-test/" + order.id() + "/confirm").with(csrf()))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("CONFIRMED"))
            .andExpect(jsonPath("$.data.paymentStatus").value("PAID"));
        int historyCount = orders.get(order.id()).histories().size();
        simulation.confirmForTesting(order.id());
        assertEquals(historyCount, orders.get(order.id()).histories().size());
        assertEquals(5, variant.getReservedQuantity());
        assertTrue(orders.get(order.id()).histories().getLast().note().contains("SIMULATED-ORDER-"));
    }

    @Test
    void temporaryConfirmationCannotRestoreExpiredOrder() {
        OrderResponse order = create();
        clock.advanceSeconds(300);
        OrderResponse result = simulation.confirmForTesting(order.id());
        assertEquals("CANCELLED", result.status());
        assertEquals("REFUND_PENDING", result.paymentStatus());
        assertEquals(2, variant.getReservedQuantity());
    }

    @Test
    void temporaryApiRequiresAdmin() throws Exception {
        mockMvc.perform(get("/api/v1/order-test/enabled")).andExpect(status().isUnauthorized());
    }
}
