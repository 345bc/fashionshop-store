package com.huit.zella.order;

import com.huit.zella.auth.User;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.inventory.InventoryService;
import com.huit.zella.orderreturn.ReturnRepository;
import com.huit.zella.productvariant.ProductVariant;
import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.time.*;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class OrderOnlinePaymentTest {
    private final Clock clock = Clock.fixed(Instant.parse("2026-10-09T00:00:00Z"), ZoneOffset.UTC);
    private Order order;
    private ProductVariant variant;
    private OrderService service;

    @BeforeEach void setup() {
        order = new Order(); order.setId(1L); order.setCode("ORD-PAYMENT"); order.setPaymentMethod("ONLINE");
        order.setTotalAmount(new BigDecimal("530000")); order.setPaymentExpiresAt(LocalDateTime.now(clock).plusMinutes(5));
        variant = new ProductVariant(); variant.setId(10L); variant.setStockQuantity(10); variant.setReservedQuantity(2);
        OrderItem item = new OrderItem(); item.setId(20L); item.setVariant(variant); item.setOrder(order);
        item.setQuantity(2); item.setUnitPrice(new BigDecimal("250000")); order.getItems().add(item);
        OrderRepository repository = (OrderRepository) Proxy.newProxyInstance(OrderRepository.class.getClassLoader(),
                new Class<?>[]{OrderRepository.class}, (proxy, method, args) -> switch (method.getName()) {
                    case "findByIdForUpdate" -> Optional.of(order);
                    case "existsByOnlineTransactionIdAndIdNot" -> false;
                    case "flush" -> null;
                    default -> throw new UnsupportedOperationException(method.getName());
                });
        ReturnRepository returns = (ReturnRepository) Proxy.newProxyInstance(ReturnRepository.class.getClassLoader(),
                new Class<?>[]{ReturnRepository.class}, (proxy, method, args) -> {
                    if (method.getName().equals("committedQuantity")) return 0L;
                    throw new UnsupportedOperationException(method.getName());
                });
        InventoryService inventory = new InventoryService(null, null, null, null) {
            @Override public ProductVariant lockVariant(Long id) { return variant; }
            @Override public void changeStockAndReservation(ProductVariant value, int stock, int reserved,
                    String type, String reference, String note, User actor) {
                value.setStockQuantity(stock); value.setReservedQuantity(reserved);
            }
        };
        service = new OrderService(repository, null, inventory, returns, clock, null, null, org.mockito.Mockito.mock(com.huit.zella.loyalty.LoyaltyService.class), org.mockito.Mockito.mock(com.huit.zella.voucher.VoucherService.class));
    }

    @Test void paidOrderIsAutomaticallyConfirmedButStockIsNotShippedYet() {
        service.recordOnlinePayment(1L, new BigDecimal("530000"), "BANK-1");
        assertEquals(OrderStatus.CONFIRMED, order.getStatus()); assertEquals("PAID", order.getPaymentStatus());
        assertEquals(10, variant.getStockQuantity()); assertEquals(2, variant.getReservedQuantity());
        int historyCount = order.getHistories().size();
        service.recordOnlinePayment(1L, new BigDecimal("530000"), "BANK-1");
        assertEquals(historyCount, order.getHistories().size());
        assertThrows(BusinessException.class, () -> service.recordOnlinePayment(1L, new BigDecimal("530000"), "BANK-2"));
    }

    @Test void moneyArrivingAtDeadlineReleasesReservationAndRequiresRefund() {
        order.setPaymentExpiresAt(LocalDateTime.now(clock));
        service.recordOnlinePayment(1L, new BigDecimal("530000"), "BANK-LATE");
        assertEquals(OrderStatus.CANCELLED, order.getStatus()); assertEquals("REFUND_PENDING", order.getPaymentStatus());
        assertEquals(10, variant.getStockQuantity()); assertEquals(0, variant.getReservedQuantity());
        service.recordOnlinePayment(1L, new BigDecimal("530000"), "BANK-LATE");
        assertEquals(0, variant.getReservedQuantity());
    }

    @Test void schedulerExpiryReleasesExactlyOnceAndLatePaymentDoesNotReopenOrder() {
        order.setPaymentExpiresAt(LocalDateTime.now(clock).minusSeconds(1));
        assertTrue(service.expire(1L)); assertFalse(service.expire(1L));
        assertEquals("EXPIRED", order.getPaymentStatus()); assertEquals(0, variant.getReservedQuantity());
        service.recordOnlinePayment(1L, new BigDecimal("530000"), "BANK-LATE");
        assertEquals(OrderStatus.CANCELLED, order.getStatus()); assertEquals("REFUND_PENDING", order.getPaymentStatus());
        assertEquals(0, variant.getReservedQuantity());
    }

    @Test void wrongAmountNeverConfirmsOrConsumesReservation() {
        assertThrows(BusinessException.class, () -> service.recordOnlinePayment(1L, new BigDecimal("500000"), "BANK-1"));
        assertEquals(OrderStatus.PENDING, order.getStatus()); assertEquals("PENDING", order.getPaymentStatus());
        assertNull(order.getOnlineTransactionId()); assertEquals(2, variant.getReservedQuantity());
    }
}
