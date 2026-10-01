package com.huit.zella.color;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CreateColorRequest(
        @NotBlank(message = "Color name is required")
        @Size(max = 50, message = "Color name must not exceed 50 characters")
        String name,
        @Pattern(regexp = "|#[0-9A-Fa-f]{6}", message = "Hex code must use the #RRGGBB format")
        String hexCode,
        @NotBlank(message = "Color code is required")
        @Size(max = 10, message = "Color code must not exceed 10 characters")
        @Pattern(regexp = "[A-Za-z0-9_-]+", message = "Color code may contain letters, numbers, underscores and hyphens")
        String code
) {
}
