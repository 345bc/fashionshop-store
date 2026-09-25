package com.huit.zella.product;

import com.huit.zella.auth.Role;
import com.huit.zella.auth.User;
import com.huit.zella.category.Category;
import com.huit.zella.category.CategoryResponse;
import com.huit.zella.sizeguide.SizeGuideResponse;
import com.huit.zella.supplier.SupplierRespone;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.Set;
import java.util.stream.Collectors;

public record ProductResponse(
        Long id,
        String name,
        String slug,
        String description,
        String style,
        String occasion,
        BigDecimal basePrice,
        boolean isActive,
        CategoryResponse categoryId,
        SupplierRespone supplierId,
        SizeGuideResponse sizeGuideId,
        Instant createdAt,
        Instant updatedAt
) {
    public static ProductResponse createProductResponse(Product product) {
        CategoryResponse categoryResponse = product.getCategory() == null
                ? null
                : CategoryResponse.create(product.getCategory());

        SupplierRespone supplierRespone = product.getSupplier() == null
                ? null
                : SupplierRespone.from(product.getSupplier());

        SizeGuideResponse sizeGuideResponse = product.getSizeGuide() == null
                ? null
                : SizeGuideResponse.create(product.getSizeGuide());


        return new ProductResponse(
                product.getId(),
                product.getName(),
                product.getSlug(),
                product.getDescription(),
                product.getStyle(),
                product.getOccasion(),
                product.getBasePrice(),
                product.isActive(),
                categoryResponse,
                supplierRespone,
                sizeGuideResponse,
                product.getCreatedAt(),
                product.getUpdatedAt()
        );
    }
}