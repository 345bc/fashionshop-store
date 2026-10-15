package com.huit.zella.sizeguide;

public record SizeGuideResponse(
        Long id,
        String name,
        String description,
        String guideImageUrl,
        Boolean isActive
) {
    public static SizeGuideResponse from(SizeGuide sizeGuide) {
        return new SizeGuideResponse(
                sizeGuide.getId(), sizeGuide.getName(), sizeGuide.getDescription(), sizeGuide.getGuideImageUrl(), sizeGuide.getIsActive()
        );
    }
}
