package com.huit.zella.productvariant;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

public record CreateProductVariantRequest(
        @NotNull(message = "Product is required")
        Long productId,

        @NotNull(message = "Size is required")
        Integer sizeId,

        @NotNull(message = "Color is required")
        Integer colorId,

        @NotNull(message = "Price is required")
        @DecimalMin(value = "0.0", inclusive = false, message = "Price must be greater than 0")
        @Digits(integer = 16, fraction = 2, message = "Price must have at most 16 integer digits and 2 decimal places")
        BigDecimal price,

        @NotNull(message = "Cost price is required")
        @DecimalMin(value = "0.0", message = "Cost price must not be negative")
        @Digits(integer = 16, fraction = 2, message = "Cost price must have at most 16 integer digits and 2 decimal places")
        BigDecimal costPrice,

        @NotNull(message = "Stock quantity is required")
        @Min(value = 0, message = "Stock quantity must not be negative")
        Integer stockQuantity,

        @NotNull(message = "Reserved quantity is required")
        @Min(value = 0, message = "Reserved quantity must not be negative")
        Integer reservedQuantity,

        Boolean isActive
) {
}
