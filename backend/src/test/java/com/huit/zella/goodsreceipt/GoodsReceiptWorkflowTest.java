package com.huit.zella.goodsreceipt;

import com.huit.zella.auth.User;
import com.huit.zella.category.Category;
import com.huit.zella.color.Color;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.inventory.CreateInventoryAdjustmentRequest;
import com.huit.zella.inventory.InventoryService;
import com.huit.zella.product.Product;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.size.Size;
import com.huit.zella.sizeguide.SizeGuide;
import com.huit.zella.supplier.Supplier;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest @Transactional
class GoodsReceiptWorkflowTest extends com.huit.zella.inventory.WarehouseFixture {
    @Autowired GoodsReceiptService receipts;
    @Autowired InventoryService inventory;
    private GoodsReceiptResponse draft() {
        return receipts.create(new CreateGoodsReceiptRequest(supplier.getId(), "Test",
            List.of(new CreateGoodsReceiptRequest.Item(variant.getId(), 5, new BigDecimal("200")))), actor.getId());
    }
    @Test
    void draftDoesNotChangeStockAndPostUpdatesStockCostAndHistoryOnce() {
        var receipt = draft();
        assertEquals(10, variant.getStockQuantity());
        assertEquals("DRAFT", receipt.status());
        var posted = receipts.post(receipt.id(), actor.getId());
        em.flush(); em.clear();
        var stored = em.find(ProductVariant.class, variant.getId());
        assertEquals(15, stored.getStockQuantity());
        assertEquals(new BigDecimal("133.33"), stored.getCostPrice());
        assertEquals(new BigDecimal("1000.00"), posted.totalAmount().setScale(2));
        var history = inventory.history(stored.getId(), org.springframework.data.domain.PageRequest.of(0, 100, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "id"))).getContent();
        assertEquals(1, history.size());
        assertEquals(5, history.getFirst().quantityChange());
        assertEquals("INVALID_RECEIPT_STATUS",
            assertThrows(BusinessException.class, () -> receipts.post(receipt.id(), actor.getId())).getCode());
    }
    @Test
    void reversingReceiptRestoresStockAndCostAndKeepsHistory() {
        var receipt = draft();
        receipts.post(receipt.id(), actor.getId());
        receipts.cancel(receipt.id(), actor.getId());
        em.flush(); em.clear();
        var stored = em.find(ProductVariant.class, variant.getId());
        assertEquals(10, stored.getStockQuantity());
        assertEquals(new BigDecimal("100.00"), stored.getCostPrice());
        assertEquals(2, inventory.history(stored.getId(), org.springframework.data.domain.PageRequest.of(0, 100, org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "id"))).getContent().size());
        assertEquals("CANCELLED", receipts.get(receipt.id()).status());
    }
    @Test
    void laterAdjustmentBlocksReceiptReversal() {
        var receipt = draft(); receipts.post(receipt.id(), actor.getId());
        inventory.adjust(new CreateInventoryAdjustmentRequest("Kiểm kê",
            List.of(new CreateInventoryAdjustmentRequest.Item(variant.getId(), 15, 14))), actor.getId());
        assertEquals("RECEIPT_HAS_LATER_MOVEMENT",
            assertThrows(BusinessException.class, () -> receipts.cancel(receipt.id(), actor.getId())).getCode());
    }
    @Test
    void staleCountAndCountBelowReservedAreRejected() {
        assertEquals("STALE_INVENTORY", assertThrows(BusinessException.class, () ->
            inventory.adjust(new CreateInventoryAdjustmentRequest("Kiểm kê",
                List.of(new CreateInventoryAdjustmentRequest.Item(variant.getId(), 9, 8))), actor.getId())).getCode());
        assertEquals("RESERVED_STOCK", assertThrows(BusinessException.class, () ->
            inventory.adjust(new CreateInventoryAdjustmentRequest("Kiểm kê",
                List.of(new CreateInventoryAdjustmentRequest.Item(variant.getId(), 10, 1))), actor.getId())).getCode());
    }
    @Test
    void partialAndFullPaymentsCannotExceedDebt() {
        var receipt = draft(); receipts.post(receipt.id(), actor.getId());
        var partial = receipts.pay(receipt.id(), new CreateSupplierPaymentRequest(new BigDecimal("400"), "CASH", null), actor.getId());
        assertEquals("PARTIAL", partial.paymentStatus());
        assertEquals(new BigDecimal("600.00"), partial.remainingAmount().setScale(2));
        var paid = receipts.pay(receipt.id(), new CreateSupplierPaymentRequest(new BigDecimal("600"), "BANK_TRANSFER", null), actor.getId());
        assertEquals("PAID", paid.paymentStatus());
        assertEquals(2, paid.payments().size());
        assertEquals("PAYMENT_EXCEEDS_BALANCE", assertThrows(BusinessException.class, () ->
            receipts.pay(receipt.id(), new CreateSupplierPaymentRequest(BigDecimal.ONE, "CASH", null), actor.getId())).getCode());
    }
    @Test
    void mergesRepeatedSkuAndRejectsWrongSupplier() {
        var receipt = receipts.create(new CreateGoodsReceiptRequest(supplier.getId(), null, List.of(
            new CreateGoodsReceiptRequest.Item(variant.getId(), 2, BigDecimal.TEN),
            new CreateGoodsReceiptRequest.Item(variant.getId(), 3, BigDecimal.TEN))), actor.getId());
        assertEquals(1, receipt.items().size()); assertEquals(5, receipt.items().getFirst().quantity());
        var other = new Supplier(); other.setName("Other supplier"); em.persist(other);
        assertEquals("INVALID_RECEIPT_VARIANT", assertThrows(BusinessException.class, () ->
            receipts.create(new CreateGoodsReceiptRequest(other.getId(), null,
                List.of(new CreateGoodsReceiptRequest.Item(variant.getId(), 1, BigDecimal.TEN))), actor.getId())).getCode());
    }
}
