package com.huit.zella.inventory;
import com.huit.zella.productvariant.ProductVariant;
import java.math.BigDecimal;
public record InventoryResponse(Long variantId, String sku, String productName, String categoryName,
    Long supplierId, String supplierName, String sizeName, String colorName, boolean isActive,
    Integer stockQuantity, Integer reservedQuantity, Integer availableQuantity, BigDecimal costPrice, BigDecimal price) {
    public static InventoryResponse from(ProductVariant v) {
        var p = v.getProduct();
        return new InventoryResponse(v.getId(), v.getSku(), p.getName(), p.getCategory().getName(),
            p.getSupplier() == null ? null : p.getSupplier().getId(), p.getSupplier() == null ? "—" : p.getSupplier().getName(), v.getSize().getName(), v.getColor().getName(),
            v.isActive() && p.isActive(), v.getStockQuantity(), v.getReservedQuantity(),
            v.getStockQuantity() - v.getReservedQuantity(), v.getCostPrice(), v.getPrice());
    }
}
