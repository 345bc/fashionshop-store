package com.huit.zella.cart;

import jakarta.validation.constraints.*;

public record CartItemRequest(@NotNull @Positive Long variantId, @NotNull @Min(1) @Max(999) Integer quantity) {}
