package com.huit.zella.cart;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

public record MergeCartRequest(
        @NotBlank @Pattern(regexp = "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89aAbB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}") String mergeKey,
        @NotNull @Size(max = 200) List<@NotNull @Valid CartItemRequest> items) {}
