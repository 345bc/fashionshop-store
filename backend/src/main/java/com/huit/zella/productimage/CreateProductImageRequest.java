package com.huit.zella.productimage;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateProductImageRequest(
        @NotNull(message = "Product is required")
        Long productId,
        @NotBlank(message = "Image URL is required")
        @Size(max = 500, message = "Image URL must not exceed 500 characters")
        String imageUrl,
        @NotNull(message = "Primary flag is required")
        Boolean isPrimary,
        @NotNull(message = "Display order is required")
        @Min(value = 0, message = "Display order must not be negative")
        Integer displayOrder
) {
}
