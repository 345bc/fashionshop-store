package com.huit.zella.category;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import jakarta.validation.constraints.Pattern;

public record CreateCategoryRequest(
        @NotBlank(message = "Category name is required")
        @Size(max = 100, message = "Category name must not exceed 100 characters")
        String name,
        Long parentId,
        Boolean isActive,
        @Size(max = 2048)
        @Pattern(regexp = "(?i)^https?://\\S+$", message = "Image URL must use HTTP or HTTPS")
        String imageUrl
) {
    public CreateCategoryRequest(String name, Long parentId, Boolean isActive) {
        this(name, parentId, isActive, null);
    }
}
