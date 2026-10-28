package com.huit.zella.order;

import com.huit.zella.auth.User;
import com.huit.zella.cart.CartService;
import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

class OrderCheckoutRecoveryTest {
    private OrderService service;
    private Order order;
    private final String token = UUID.randomUUID().toString();

    @BeforeEach void setup() throws Exception {
        order = new Order(); order.setId(1L); order.setCode("ORD-TEST");
        order.setCheckoutTokenHash(HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8))));
        order.setTotalAmount(new BigDecimal("33000")); order.setPaymentExpiresAt(LocalDateTime.now().plusMinutes(5));
        OrderRepository repository = (OrderRepository) Proxy.newProxyInstance(OrderRepository.class.getClassLoader(), new Class<?>[]{OrderRepository.class},
            (proxy, method, args) -> switch (method.getName()) {
                case "findByCheckoutTokenHash" -> order.getCheckoutTokenHash().equals(args[0]) ? Optional.of(order) : Optional.empty();
                case "findByCode" -> order.getCode().equals(args[0]) ? Optional.of(order) : Optional.empty();
                case "findByIdForUpdate" -> Optional.of(order);
                default -> throw new AssertionError("Retry must not create or reserve again: " + method.getName());
            });
        CartService cartService = new CartService(null, null, null, null, null, null) {
            @Override public void prepareCheckout(Long userId) {}
            @Override public void consume(Long userId, List<CreateOrderRequest.Item> purchased) { fail("Retry must not consume the cart again"); }
        };
        service = new OrderService(repository, null, null, null, Clock.systemUTC(), null, cartService, org.mockito.Mockito.mock(com.huit.zella.loyalty.LoyaltyService.class), org.mockito.Mockito.mock(com.huit.zella.voucher.VoucherService.class), org.mockito.Mockito.mock(com.huit.zella.mail.OrderEmails.class));
    }

    @Test void retryReturnsSameGuestOrderWithoutReservingOrConsumingAgain() {
        CreateCheckoutOrderRequest request = new CreateCheckoutOrderRequest("Khách", "0900000000", "Địa chỉ", null,
                "STANDARD", List.of(new CreateOrderRequest.Item(10L, 1)), token);
        CheckoutOrderResponse result = service.createCheckout(request, null);
        assertEquals(order.getId(), result.id()); assertEquals(token, result.checkoutToken());
        assertEquals(order.getTotalAmount(), result.totalAmount());
    }

    @Test void retryCannotClaimAnotherAccountsOrder() {
        User owner = new User(); owner.setId(7L); order.setCustomer(owner);
        CreateCheckoutOrderRequest request = new CreateCheckoutOrderRequest("Khách", "0900000000", "Địa chỉ", null,
                "STANDARD", List.of(new CreateOrderRequest.Item(10L, 1)), token);
        assertThrows(BusinessException.class, () -> service.createCheckout(request, 8L));
        assertEquals(order.getId(), service.createCheckout(request, 7L).id());
    }

    @Test void cancelledOrderCanBeCancelledAgainButPaidOrderCannot() {
        order.setStatus(OrderStatus.CANCELLED);
        assertEquals("CANCELLED", service.cancelCheckout(order.getCode(), token).status());
        order.setStatus(OrderStatus.CONFIRMED); order.setPaymentStatus("PAID");
        assertThrows(BusinessException.class, () -> service.cancelCheckout(order.getCode(), token));
    }

    @Test void statusAndCancellationRequireTheCorrectCapabilityToken() {
        assertThrows(BusinessException.class, () -> service.checkoutStatus(order.getCode(), "wrong-token"));
        assertThrows(BusinessException.class, () -> service.cancelCheckout(order.getCode(), "wrong-token"));
        assertNull(service.checkoutStatus(order.getCode(), token).checkoutToken());
    }
}
