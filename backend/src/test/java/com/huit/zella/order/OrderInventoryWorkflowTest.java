package com.huit.zella.order;

import com.huit.zella.goodsreceipt.*;
import com.huit.zella.inventory.*;
import com.huit.zella.orderreturn.*;
import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@Transactional
class OrderInventoryWorkflowTest extends WarehouseFixture {
    @Autowired OrderService orders;
    @Autowired ReturnService returns;
    @Autowired GoodsReceiptService receipts;
    @Autowired InventoryService inventory;

    private OrderResponse create(int quantity) {
        return orders.create(new CreateOrderRequest(actor.getId(), "Khách test", "0900000000", "Địa chỉ test", null,
            BigDecimal.ZERO, "ONLINE", List.of(new CreateOrderRequest.Item(variant.getId(), quantity))), actor.getId());
    }
    private void paid(Long id) {
        orders.recordOnlinePayment(id, orders.get(id).totalAmount(), "TEST-" + java.util.UUID.randomUUID());
    }
    private OrderResponse shipped(int quantity) {
        OrderResponse order = create(quantity);
        paid(order.id());
        orders.ship(order.id(), actor.getId());
        return orders.get(order.id());
    }
    private ReturnResponse draftReturn(OrderResponse order, int quantity) {
        return returns.create(new CreateReturnRequest(order.id(), "Test return",
            List.of(new CreateReturnRequest.Item(order.items().getFirst().id(), quantity))), actor.getId());
    }
    private ReturnResponse receive(ReturnResponse document, String condition) {
        returns.approve(document.id(), actor.getId());
        return returns.receive(document.id(), new ReceiveReturnRequest(List.of(
            new ReceiveReturnRequest.Item(document.items().getFirst().id(), condition))), actor.getId());
    }

    @Test
    void createReservesAndCancelReleasesExactlyOnceWithoutChangingPhysicalStock() {
        OrderResponse order = create(3);
        assertEquals(10, variant.getStockQuantity());
        assertEquals(5, variant.getReservedQuantity());
        orders.cancel(order.id(), "Khách hủy", actor.getId());
        assertEquals(10, variant.getStockQuantity());
        assertEquals(2, variant.getReservedQuantity());
        assertThrows(BusinessException.class, () -> orders.cancel(order.id(), "Lần hai", actor.getId()));
        assertEquals(2, inventory.history(variant.getId()).size());
    }

    @Test
    void insufficientAvailabilityDoesNotCreateOrderOrReservation() {
        assertEquals("INSUFFICIENT_STOCK", assertThrows(BusinessException.class, () -> create(9)).getCode());
        assertEquals(10, variant.getStockQuantity());
        assertEquals(2, variant.getReservedQuantity());
    }

    @Test
    void shipmentConsumesPhysicalAndReservedStockOnceAndSnapshotsCost() {
        OrderResponse order = create(3);
        assertThrows(BusinessException.class, () -> orders.ship(order.id(), actor.getId()));
        paid(order.id());
        orders.ship(order.id(), actor.getId());
        assertEquals(7, variant.getStockQuantity());
        assertEquals(2, variant.getReservedQuantity());
        assertThrows(BusinessException.class, () -> orders.ship(order.id(), actor.getId()));
        assertThrows(BusinessException.class, () -> orders.cancel(order.id(), "Đã xuất", actor.getId()));
        orders.deliver(order.id(), actor.getId());
        assertEquals("PAID", orders.get(order.id()).paymentStatus());
        assertEquals(2, inventory.history(variant.getId()).size());
        assertEquals(5, inventory.history(variant.getId()).getFirst().beforeReserved());
        assertEquals(2, inventory.history(variant.getId()).getFirst().afterReserved());
    }

    @Test
    void onlinePaymentConfirmsOrderAndPaidCancellationRequiresRefundAcknowledgement() {
        OrderResponse order = create(2);
        assertEquals("INVALID_ORDER_STATUS", assertThrows(BusinessException.class, () -> orders.ship(order.id(), actor.getId())).getCode());
        paid(order.id());
        orders.cancel(order.id(), "Khách hủy", actor.getId());
        assertEquals("REFUND_PENDING", orders.get(order.id()).paymentStatus());
        orders.refunded(order.id(), "Refund transaction", actor.getId());
        assertEquals("REFUNDED", orders.get(order.id()).paymentStatus());
        assertThrows(BusinessException.class, () -> orders.refunded(order.id(), "Duplicate", actor.getId()));
    }

    @Test
    void intactReturnRestocksAtShipmentCostAndCannotRestockTwice() {
        OrderResponse order = shipped(3);
        orders.deliver(order.id(), actor.getId());
        variant.setCostPrice(new BigDecimal("200"));
        ReturnResponse document = draftReturn(order, 3);
        ReturnResponse received = receive(document, "INTACT");
        assertEquals(10, variant.getStockQuantity());
        assertEquals(new BigDecimal("170.00"), variant.getCostPrice());
        assertEquals(new BigDecimal("900.00"), received.refundAmount().setScale(2));
        assertThrows(BusinessException.class, () -> returns.receive(document.id(), new ReceiveReturnRequest(List.of(
            new ReceiveReturnRequest.Item(document.items().getFirst().id(), "INTACT"))), actor.getId()));
        assertThrows(BusinessException.class, () -> returns.complete(document.id(), new CompleteReturnRequest("NO_REFUND", "Test"), actor.getId()));
        returns.complete(document.id(), new CompleteReturnRequest("BANK_TRANSFER", "Refund TX"), actor.getId());
        assertEquals("COMPLETED", returns.list(order.id()).getFirst().status());
    }

    @Test
    void damagedReturnsDoNotIncreaseSaleableStockAndCannotExceedSoldQuantity() {
        OrderResponse order = shipped(3);
        orders.deliver(order.id(), actor.getId());
        ReturnResponse document = draftReturn(order, 2);
        assertEquals("RETURN_EXCEEDS_SOLD", assertThrows(BusinessException.class, () -> draftReturn(order, 2)).getCode());
        receive(document, "DAMAGED");
        assertEquals(7, variant.getStockQuantity());
        assertEquals("RETURN_DAMAGED", inventory.history(variant.getId()).getFirst().movementType());
        assertEquals(0, inventory.history(variant.getId()).getFirst().quantityChange());
        assertThrows(BusinessException.class, () -> returns.cancel(document.id(), "Already received", actor.getId()));
    }

    @Test
    void rejectedReturnFreesReturnAllowanceAndFailedDeliveryRefundsOnlinePayment() {
        OrderResponse order = shipped(3);
        assertEquals("FULL_SHIPMENT_RETURN_REQUIRED", assertThrows(BusinessException.class, () -> draftReturn(order, 1)).getCode());
        ReturnResponse rejected = draftReturn(order, 3);
        returns.reject(rejected.id(), "Khách nhận được hàng", actor.getId());
        ReturnResponse accepted = draftReturn(order, 3);
        assertThrows(BusinessException.class, () -> orders.deliver(order.id(), actor.getId()));
        ReturnResponse received = receive(accepted, "INTACT");
        assertEquals(10, variant.getStockQuantity());
        assertEquals(new BigDecimal("900.00"), received.refundAmount().setScale(2));
        assertEquals("RETURNED", orders.get(order.id()).status());
        returns.complete(accepted.id(), new CompleteReturnRequest("BANK_TRANSFER", "Hoàn tiền giao thất bại"), actor.getId());
    }

    @Test
    void receiptReversalIsBlockedByReservationMovement() {
        GoodsReceiptResponse receipt = receipt();
        receipts.post(receipt.id(), actor.getId());
        create(3);
        assertEquals("RECEIPT_HAS_LATER_MOVEMENT", assertThrows(BusinessException.class, () -> receipts.cancel(receipt.id(), actor.getId())).getCode());
    }

    @Test
    void failedPrepaidDeliveryRefundsShippingAndRecordsRefundedState() {
        OrderResponse order = orders.create(new CreateOrderRequest(actor.getId(), "Test", "0900000000", "Test", null,
            new BigDecimal("30"), "ONLINE",
            List.of(new CreateOrderRequest.Item(variant.getId(), 2))), actor.getId());
        paid(order.id());
        orders.ship(order.id(), actor.getId());
        ReturnResponse document = draftReturn(order, 2);
        ReturnResponse received = receive(document, "INTACT");
        assertEquals(new BigDecimal("630.00"), received.refundAmount().setScale(2));
        returns.complete(document.id(), new CompleteReturnRequest("BANK_TRANSFER", "Full parcel refund"), actor.getId());
        assertEquals("REFUNDED", orders.get(order.id()).paymentStatus());
    }

    private GoodsReceiptResponse receipt() {
        return receipts.create(new CreateGoodsReceiptRequest(supplier.getId(), "Test",
            List.of(new CreateGoodsReceiptRequest.Item(variant.getId(), 5, new BigDecimal("200")))), actor.getId());
    }

    @Test
    void supplierReturnReducesUnpaidDebtAndDoesNotConsumeHeldStock() {
        GoodsReceiptResponse receipt = receipt();
        receipts.post(receipt.id(), actor.getId());
        GoodsReceiptResponse returned = receipts.returnToSupplier(receipt.id(), new CreateSupplierReturnRequest("Trả 2 áo",
            List.of(new CreateSupplierReturnRequest.Item(variant.getId(), 2))), actor.getId());
        assertEquals(13, variant.getStockQuantity());
        assertEquals(2, variant.getReservedQuantity());
        assertEquals(new BigDecimal("600.00"), returned.remainingAmount().setScale(2));
        assertEquals(2, returned.items().getFirst().returnedQuantity());
        create(10);
        assertEquals("INSUFFICIENT_STOCK", assertThrows(BusinessException.class, () ->
            receipts.returnToSupplier(receipt.id(), new CreateSupplierReturnRequest("Không được lấy hàng đã giữ",
                List.of(new CreateSupplierReturnRequest.Item(variant.getId(), 2))), actor.getId())).getCode());
        assertThrows(BusinessException.class, () -> receipts.returnToSupplier(receipt.id(), new CreateSupplierReturnRequest("Vượt phiếu",
            List.of(new CreateSupplierReturnRequest.Item(variant.getId(), 4))), actor.getId()));
        assertThrows(BusinessException.class, () -> receipts.pay(receipt.id(),
            new CreateSupplierPaymentRequest(new BigDecimal("700"), "CASH", null), actor.getId()));
        assertThrows(BusinessException.class, () -> receipts.cancel(receipt.id(), actor.getId()));
    }

    @Test
    void paidSupplierReturnCreatesRefundBalanceAndPreventsOverRefund() {
        GoodsReceiptResponse receipt = receipt();
        receipts.post(receipt.id(), actor.getId());
        receipts.pay(receipt.id(), new CreateSupplierPaymentRequest(new BigDecimal("1000"), "CASH", null), actor.getId());
        GoodsReceiptResponse returned = receipts.returnToSupplier(receipt.id(), new CreateSupplierReturnRequest("Trả 2 áo",
            List.of(new CreateSupplierReturnRequest.Item(variant.getId(), 2))), actor.getId());
        assertEquals(new BigDecimal("400.00"), returned.supplierRefundDue().setScale(2));
        assertEquals(0, returned.remainingAmount().signum());
        receipts.supplierRefund(receipt.id(), new CreateSupplierPaymentRequest(new BigDecimal("100"), "CASH", "First refund"), actor.getId());
        GoodsReceiptResponse finalRefund = receipts.supplierRefund(receipt.id(),
            new CreateSupplierPaymentRequest(new BigDecimal("300"), "BANK_TRANSFER", "Final refund"), actor.getId());
        assertEquals(0, finalRefund.supplierRefundDue().signum());
        assertEquals(2, finalRefund.refunds().size());
        assertThrows(BusinessException.class, () -> receipts.supplierRefund(receipt.id(),
            new CreateSupplierPaymentRequest(BigDecimal.ONE, "CASH", null), actor.getId()));
    }
}
