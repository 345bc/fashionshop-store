package com.huit.zella.category;

public record CategorySummaryResponse(
        Long id,
        String name,
        String slug
) {
    public static CategorySummaryResponse from(Category category) {
        if (category == null) {
            return null;
        }

        return new CategorySummaryResponse(
                category.getId(),
                category.getName(),
                category.getSlug()
        );
    }
}
