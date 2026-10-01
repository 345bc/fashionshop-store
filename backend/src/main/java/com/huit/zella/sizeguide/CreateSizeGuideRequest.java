package com.huit.zella.sizeguide;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateSizeGuideRequest(
        @NotBlank(message = "Size guide name is required")
        @Size(max = 100, message = "Size guide name must not exceed 100 characters")
        String name,
        @Size(max = 500, message = "Description must not exceed 500 characters")
        String description,
        @Size(max = 500, message = "Guide image URL must not exceed 500 characters")
        String guideImageUrl,
        Boolean isActive
) {
}
