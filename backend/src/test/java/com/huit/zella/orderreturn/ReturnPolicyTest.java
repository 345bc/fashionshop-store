package com.huit.zella.orderreturn;

import com.huit.zella.auth.*;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.inventory.InventoryService;
import com.huit.zella.loyalty.LoyaltyService;
import com.huit.zella.order.*;
import com.huit.zella.productvariant.ProductVariant;
import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.BeforeEach;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ReturnPolicyTest {
    private final Clock clock = Clock.fixed(Instant.parse("2026-10-15T08:00:00Z"), ZoneOffset.UTC);
    private final ReturnRepository repository = mock(ReturnRepository.class);
    private final OrderService orders = mock(OrderService.class);
    private final UserRepository users = mock(UserRepository.class);
    private final ReturnService service = new ReturnService(repository, mock(OrderRepository.class), orders, users,
        mock(InventoryService.class), mock(LoyaltyService.class), clock);
    private final Order order = new Order();
    private final OrderHistory delivered = new OrderHistory();
    private final User actor = new User();

    @BeforeEach void setup() {
        actor.setId(9L); actor.setUserName("admin"); when(users.getReferenceById(9L)).thenReturn(actor);
        order.setId(1L); order.setCode("ORD-TEST"); order.setStatus(OrderStatus.DELIVERED);
        delivered.setNewStatus("DELIVERED"); delivered.setCreatedAt(LocalDateTime.now(clock).minusDays(14));
        order.getHistories().add(delivered);
        var variant = new ProductVariant(); variant.setId(3L);
        var item = new OrderItem(); item.setId(2L); item.setVariant(variant); item.setQuantity(2); item.setUnitCost(BigDecimal.ONE);
        order.getItems().add(item);
        when(orders.lock(1L)).thenReturn(order);
        when(repository.committedQuantity(2L)).thenReturn(0L);
        when(repository.saveAndFlush(any())).thenAnswer(call -> call.getArgument(0));
    }
    private CreateReturnRequest request(int quantity) {
        return new CreateReturnRequest(1L, "Hàng không phù hợp", List.of(new CreateReturnRequest.Item(2L, quantity)));
    }
    private void rejects(String code) {
        assertEquals(code, assertThrows(BusinessException.class, () -> service.create(request(1), 9L)).getCode());
        verify(repository, never()).saveAndFlush(any());
    }
    @Test void acceptsRequestAtExactlyFourteenDays() {
        assertEquals("PENDING", service.create(request(1), 9L).status());
    }
    @Test void rejectsOneInstantBeyondFourteenDays() {
        delivered.setCreatedAt(delivered.getCreatedAt().minusNanos(1)); rejects("RETURN_EXPIRED");
    }
    @Test void rejectsMissingDeliveryHistory() { order.getHistories().clear(); rejects("DELIVERY_DATE_MISSING"); }
    @Test void rejectsNullDeliveryTimestamp() { delivered.setCreatedAt(null); rejects("DELIVERY_DATE_MISSING"); }
    @Test void rejectsFutureDeliveryTimestamp() { delivered.setCreatedAt(LocalDateTime.now(clock).plusSeconds(1)); rejects("INVALID_DELIVERY_DATE"); }
    @Test void repeatedDeliveryHistoryCannotExtendTheWindow() {
        delivered.setCreatedAt(LocalDateTime.now(clock).minusDays(15));
        var repeated = new OrderHistory(); repeated.setNewStatus("DELIVERED"); repeated.setCreatedAt(LocalDateTime.now(clock));
        order.getHistories().add(repeated); rejects("RETURN_EXPIRED");
    }
    @Test void cannotReturnMoreThanUncommittedQuantity() { when(repository.committedQuantity(2L)).thenReturn(2L); rejects("RETURN_EXCEEDS_SOLD"); }
    @Test void failedDeliveryRequiresWholeParcelWithoutDeliveryDate() {
        order.setStatus(OrderStatus.SHIPPED); order.getHistories().clear(); rejects("FULL_SHIPMENT_RETURN_REQUIRED");
        assertEquals("PENDING", service.create(request(2), 9L).status());
    }
    @Test void cannotMarkVnPayRefundAsCash() {
        var document = new ReturnRequest(); document.setId(5L); document.setOrder(order);
        document.setStatus(ReturnStatus.RECEIVED); document.setRefundAmount(BigDecimal.TEN);
        order.setOnlineTransactionId("VNPAY-123");
        when(repository.findOrderId(5L)).thenReturn(Optional.of(1L));
        when(repository.findByIdForUpdate(5L)).thenReturn(Optional.of(document));
        var error = assertThrows(BusinessException.class,
            () -> service.complete(5L, new CompleteReturnRequest("CASH", "Đã hoàn"), 9L));
        assertEquals("VNPAY_REFUND_REQUIRED", error.getCode()); assertEquals(ReturnStatus.RECEIVED, document.getStatus());
    }
    @Test void validatesNestedNullItemsNegativeIdsAndAmounts() {
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var validator = factory.getValidator();
            assertFalse(validator.validate(new CreateReturnRequest(-1L, " ", Arrays.asList((CreateReturnRequest.Item) null))).isEmpty());
            assertFalse(validator.validate(new CreateReturnRequest(1L, "Lý do", List.of(new CreateReturnRequest.Item(-2L, 0)))).isEmpty());
            assertFalse(validator.validate(new ReceiveReturnRequest(Arrays.asList((ReceiveReturnRequest.Item) null))).isEmpty());
            assertFalse(validator.validate(new ReceiveReturnRequest(List.of(new ReceiveReturnRequest.Item(1L, "INVALID")))).isEmpty());
        }
    }
}
