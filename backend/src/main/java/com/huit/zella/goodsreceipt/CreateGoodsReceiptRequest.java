package com.huit.zella.goodsreceipt;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.util.List;

public record CreateGoodsReceiptRequest(
        @NotNull(message = "Supplier ID is required")
        Long supplierId,

        @Size(max = 500, message = "Note must not exceed 500 characters")
        String note,

        @NotEmpty(message = "Items list cannot be empty")
        @Size(max = 200, message = "Items list must not exceed 200 items")
        List<@Valid Item> items
) {
    public record Item(
            @NotNull(message = "Variant ID is required")
            Long variantId,

            @NotNull(message = "Quantity is required")
            @Min(value = 1, message = "Quantity must be at least 1")
            Integer quantity,

            @NotNull(message = "Unit cost is required")
            @DecimalMin(value = "0", message = "Unit cost must be 0 or greater")
            @Digits(integer = 16, fraction = 2, message = "Unit cost must have up to 16 digits and 2 decimals")
            BigDecimal unitCost
    ) {
    }
}
