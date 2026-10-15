package com.huit.zella.goodsreceipt;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.util.List;

public record CreateSupplierReturnRequest(
        @NotBlank(message = "Reason is required")
        @Size(max = 500, message = "Reason must not exceed 500 characters")
        String reason,

        @NotEmpty(message = "Items list cannot be empty")
        @Size(max = 200, message = "Items list must not exceed 200 items")
        List<@Valid Item> items
) {
    public record Item(
            @NotNull(message = "Variant ID is required")
            Long variantId,

            @NotNull(message = "Quantity is required")
            @Positive(message = "Quantity must be positive")
            Integer quantity
    ) {}
}

