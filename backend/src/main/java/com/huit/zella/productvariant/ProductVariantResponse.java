package com.huit.zella.productvariant;

import java.math.BigDecimal;

public record ProductVariantResponse(
        Long id,
        Long productId,
        String productName,
        String sku,
        Long sizeId,
        String sizeName,
        Long colorId,
        String colorName,
        String colorCode,
        String colorHexCode,
        BigDecimal price,
        BigDecimal costPrice,
        Integer stockQuantity,
        Integer reservedQuantity,
        Integer availableQuantity,
        boolean isActive
) {
    public static ProductVariantResponse from(ProductVariant variant) {
        return new ProductVariantResponse(
                variant.getId(),
                variant.getProduct() != null ? variant.getProduct().getId() : null,
                variant.getProduct() != null ? variant.getProduct().getName() : null,
                variant.getSku(),
                variant.getSize() != null && variant.getSize().getId() != null ? variant.getSize().getId().longValue() : null,
                variant.getSize() != null ? variant.getSize().getName() : null,
                variant.getColor() != null && variant.getColor().getId() != null ? variant.getColor().getId().longValue() : null,
                variant.getColor() != null ? variant.getColor().getName() : null,
                variant.getColor() != null ? variant.getColor().getCode() : null,
                variant.getColor() != null ? variant.getColor().getHexCode() : null,
                variant.getPrice(),
                variant.getCostPrice(),
                variant.getStockQuantity(),
                variant.getReservedQuantity(),
                variant.getStockQuantity() - variant.getReservedQuantity(),
                variant.isActive()
        );
    }
}
