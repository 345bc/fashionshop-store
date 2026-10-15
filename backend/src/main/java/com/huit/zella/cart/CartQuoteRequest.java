package com.huit.zella.cart;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

public record CartQuoteRequest(@NotNull @Size(max = 200) List<@NotNull @Valid CartItemRequest> items) {}
