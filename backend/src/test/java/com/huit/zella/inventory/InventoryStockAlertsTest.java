package com.huit.zella.inventory;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.assertEquals;

@SpringBootTest
@Transactional
class InventoryStockAlertsTest extends WarehouseFixture {
    @Autowired InventoryService inventory;

    @Test
    void alertsAndFiltersUseAvailableQuantityAfterReservations() {
        var page = PageRequest.of(0, 1);
        var baseline = inventory.stockAlerts();
        variant.setReservedQuantity(4); // 6 available
        assertEquals(baseline, inventory.stockAlerts());
        assertEquals(0, inventory.list(null, supplier.getId(), "low", page).getTotalElements());

        variant.setReservedQuantity(5); // 5 available
        assertEquals(baseline.lowStock() + 1, inventory.stockAlerts().lowStock());
        assertEquals(variant.getId(), inventory.list(null, supplier.getId(), "low", page)
                .getContent().getFirst().variantId());

        variant.setReservedQuantity(10); // 0 available
        var depleted = inventory.stockAlerts();
        assertEquals(baseline.lowStock(), depleted.lowStock());
        assertEquals(baseline.outOfStock() + 1, depleted.outOfStock());
        assertEquals(0, inventory.list(null, supplier.getId(), "low", page).getTotalElements());
        assertEquals(variant.getId(), inventory.list(null, supplier.getId(), "out", page)
                .getContent().getFirst().variantId());
    }
}
