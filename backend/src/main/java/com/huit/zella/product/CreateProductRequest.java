package com.huit.zella.product;

import com.huit.zella.enums.RoleEnum;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.util.Set;

public record CreateProductRequest(
        @NotBlank(message = "Product name is required")
        @Size(max = 200, message = "Product name must not exceed 200 characters")
        String name,

        @Size(max = 5000, message = "Description must not exceed 5000 characters")
        String description,

        @Size(max = 50, message = "Style must not exceed 50 characters")
        String style,

        @Size(max = 100, message = "Occasion must not exceed 100 characters")
        String occasion,

        @NotNull(message = "Base price is required")
        @DecimalMin(value = "0.0", inclusive = false, message = "Base price must be greater than 0")
        @Digits(integer = 16, fraction = 2, message = "Base price must have at most 16 integer digits and 2 decimal places")
        BigDecimal basePrice,

        @NotNull(message = "Category is required")
        Long categoryId,

        @NotNull(message = "Supplier is required")
        Long supplierId,

        @NotNull(message = "SizeGuide is required")
        Long sizeGuideId,

        Boolean isActive
) {
}
