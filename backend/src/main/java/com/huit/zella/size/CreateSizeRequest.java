package com.huit.zella.size;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateSizeRequest(
        @NotBlank(message = "Size name is required")
        @Size(max = 20, message = "Size name must not exceed 20 characters")
        String name,
        @NotNull(message = "Display order is required")
        @Min(value = 0, message = "Display order must not be negative")
        Integer displayOrder
) {
}
