package com.huit.zella.sizeguide;

import com.huit.zella.category.Category;
import jakarta.persistence.Column;
import org.hibernate.annotations.Nationalized;

public record SizeGuideResponse(
        Long id,
        String name,
        String description,
        String guideImageUrl,
        Boolean isActive
) {
    public static SizeGuideResponse create(SizeGuide sizeGuide) {
        return new SizeGuideResponse(
                sizeGuide.getId(), sizeGuide.getName(), sizeGuide.getDescription(), sizeGuide.getGuideImageUrl(), sizeGuide.getIsActive()
        );
    }
}
