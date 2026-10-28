package com.huit.zella.order;

import com.huit.zella.common.exception.BusinessException;
import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.time.Clock;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class OrderLookupTest {
    private final Order order = order();
    private final OrderRepository repository = (OrderRepository) Proxy.newProxyInstance(
            OrderRepository.class.getClassLoader(), new Class<?>[]{OrderRepository.class}, (proxy, method, args) -> {
                if (method.getName().equals("findByCode")) return order.getCode().equals(args[0]) ? Optional.of(order) : Optional.empty();
                throw new AssertionError("Lookup must not change order or inventory: " + method.getName());
            });
    private final OrderService service = new OrderService(repository, null, null, null, Clock.systemUTC(), null, null, org.mockito.Mockito.mock(com.huit.zella.loyalty.LoyaltyService.class), org.mockito.Mockito.mock(com.huit.zella.voucher.VoucherService.class), org.mockito.Mockito.mock(com.huit.zella.mail.OrderEmails.class));

    @Test void guestCanTrackWithMatchingCodeAndRecipientPhone() {
        var response = service.lookup(new OrderLookupRequest(" ord-test ", "0900000000"));
        assertEquals("ORD-TEST", response.code());
        assertEquals("CONFIRMED", response.status());
        assertEquals("PAID", response.paymentStatus());
        assertEquals(new BigDecimal("500000"), response.items().getFirst().lineTotal());
        assertEquals(new BigDecimal("530000"), response.totalAmount());
        assertEquals(2, response.items().getFirst().quantity());
        assertEquals("Z", response.createdAt().getOffset().getId());
    }

    @Test void incorrectCodeOrPhoneReturnsSameError() {
        var wrongCode = assertThrows(BusinessException.class, () -> service.lookup(new OrderLookupRequest("ORD-UNKNOWN", "0900000000")));
        var wrongPhone = assertThrows(BusinessException.class, () -> service.lookup(new OrderLookupRequest("ORD-TEST", "0911111111")));
        assertEquals(wrongCode.getCode(), wrongPhone.getCode());
        assertEquals(wrongCode.getMessage(), wrongPhone.getMessage());
        assertEquals(404, wrongPhone.getStatus().value());
    }

    @Test void responseDoesNotExposePersonalDataOrCheckoutToken() {
        var fields = java.util.Arrays.stream(OrderLookupResponse.class.getRecordComponents()).map(java.lang.reflect.RecordComponent::getName).toList();
        assertFalse(fields.contains("address"));
        assertFalse(fields.contains("recipientName"));
        assertFalse(fields.contains("recipientPhone"));
        assertFalse(fields.contains("checkoutToken"));
        assertFalse(fields.contains("id"));
    }

    private static Order order() {
        var order = new Order();
        order.setCode("ORD-TEST"); order.setRecipientPhone("0900000000");
        order.setStatus(OrderStatus.CONFIRMED); order.setPaymentStatus("PAID");
        order.setTotalAmount(new BigDecimal("530000"));
        var item = new OrderItem(); item.setProductName("Áo sơ mi"); item.setSku("SHIRT-L");
        item.setQuantity(2); item.setUnitPrice(new BigDecimal("250000"));
        order.getItems().add(item);
        return order;
    }
}
