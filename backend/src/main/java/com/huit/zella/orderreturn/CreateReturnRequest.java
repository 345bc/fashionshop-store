package com.huit.zella.orderreturn;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

public record CreateReturnRequest(@NotNull Long orderId, @NotBlank @Size(max = 500) String reason,
    @NotEmpty @Size(max = 200) List<@Valid Item> items) {
    public record Item(@NotNull Long orderItemId, @NotNull @Positive Integer quantity) {}
}

