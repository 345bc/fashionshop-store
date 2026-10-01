package com.huit.zella.category;

public record CategoryResponse(
        Long id,
        String name,
        String slug,
        Boolean isActive,
        Long parentId,
        String parentName
) {
    public static CategoryResponse from(Category category) {
        if (category == null) {
            return null;
        }

        return new CategoryResponse(
                category.getId(),
                category.getName(),
                category.getSlug(),
                category.getIsActive(),
                category.getParent() != null ? category.getParent().getId() : null,
                category.getParent() != null ? category.getParent().getName() : null
        );
    }
}
