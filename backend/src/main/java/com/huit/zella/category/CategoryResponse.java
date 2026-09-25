package com.huit.zella.category;

import com.huit.zella.sizeguide.SizeGuideResponse;
import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;

public record CategoryResponse(
        Long id,
        String name,
        String slug,
        Boolean isActive,
        CategorySummaryResponse parent
) {
    public static CategoryResponse create(Category category) {
        if (category == null) {
            return null;
        }

        return new CategoryResponse(
                category.getId(),
                category.getName(),
                category.getSlug(),
                category.getIsActive(),
                CategorySummaryResponse.create(category.getParent())
        );
    }
}