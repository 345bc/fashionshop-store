package com.huit.zella.variantimage;

public record VariantImageResponse(
        Long id,
        Long variantId,
        String imageUrl,
        boolean isPrimary,
        int displayOrder
) {
    public static VariantImageResponse from(VariantImage image) {
        return new VariantImageResponse(image.getId(), image.getVariant().getId(),
                image.getImageUrl(), image.isPrimary(), image.getDisplayOrder());
    }
}
