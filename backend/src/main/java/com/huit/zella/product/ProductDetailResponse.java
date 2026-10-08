package com.huit.zella.product;

import com.huit.zella.common.api.PageResponse;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

public record ProductDetailResponse(
        Long id,
        String name,
        String slug,
        String description,
        String style,
        String occasion,
        BigDecimal basePrice,
        String categoryName,
        String sizeGuideUrl,
        List<ColorItem> colors,
        List<SizeItem> sizes,
        List<VariantItem> variants,
        BigDecimal averageRating,
        long reviewsCount,
        PageResponse<ReviewItem> reviews
) {
    public record ImageItem(
            Long id,
            String imageUrl,
            boolean isPrimary,
            int displayOrder
    ) {}

    public record ColorItem(
            Integer id,
            String name,
            String hexCode
    ) {}

    public record SizeItem(
            Integer id,
            String name
    ) {}

    public record VariantItem(
            Long id,
            String sku,
            Integer colorId,
            Integer sizeId,
            BigDecimal price,
            Integer stockQuantity,
            List<ImageItem> images
    ) {}

    public record ReviewItem(
            Long id,
            String customerName,
            int rating,
            String comment,
            String colorName,
            String sizeName,
            Instant createdAt,
            String adminReply,
            Instant repliedAt
    ) {}
}
