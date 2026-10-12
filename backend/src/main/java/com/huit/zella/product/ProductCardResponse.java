package com.huit.zella.product;

import java.math.BigDecimal;
import java.util.List;

public record ProductCardResponse(
        Long id,
        String name,
        String slug,
        BigDecimal basePrice,
        BigDecimal salePrice,
        Integer discountPercent,
        String imageUrl,
        List<ColorItem> colors,
        String badge,
        BigDecimal averageRating,
        Long reviewsCount
) {
    public record ColorItem(
            Integer id,
            String name,
            String hexCode,
            String imageUrl
    ) {}
}
