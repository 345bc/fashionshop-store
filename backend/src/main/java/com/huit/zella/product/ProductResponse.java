package com.huit.zella.product;

import java.math.BigDecimal;
import java.time.Instant;

public record ProductResponse(
        Long id,
        String name,
        String slug,
        String description,
        String style,
        String occasion,
        BigDecimal basePrice,
        boolean isActive,
        Long categoryId,
        String categoryName,
        Long supplierId,
        String supplierName,
        Long sizeGuideId,
        String sizeGuideName,
        Instant createdAt,
        Instant updatedAt
) {
    public static ProductResponse from(Product product) {
        return new ProductResponse(
                product.getId(),
                product.getName(),
                product.getSlug(),
                product.getDescription(),
                product.getStyle(),
                product.getOccasion(),
                product.getBasePrice(),
                product.isActive(),
                product.getCategory() != null ? product.getCategory().getId() : null,
                product.getCategory() != null ? product.getCategory().getName() : null,
                product.getSupplier() != null ? product.getSupplier().getId() : null,
                product.getSupplier() != null ? product.getSupplier().getName() : null,
                product.getSizeGuide() != null ? product.getSizeGuide().getId() : null,
                product.getSizeGuide() != null ? product.getSizeGuide().getName() : null,
                product.getCreatedAt(),
                product.getUpdatedAt()
        );
    }
}
