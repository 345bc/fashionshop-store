package com.huit.zella.productimage;

public record ProductImageResponse(
        Long id,
        Long productId,
        String imageUrl,
        boolean isPrimary,
        int displayOrder
) {
    public static ProductImageResponse from(ProductImage image) {
        return new ProductImageResponse(image.getId(), image.getProduct().getId(),
                image.getImageUrl(), image.isPrimary(), image.getDisplayOrder());
    }
}
