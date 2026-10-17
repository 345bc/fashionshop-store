package com.huit.zella.orderreturn;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

public record ReceiveReturnRequest(@NotEmpty @Size(max = 200) List<@NotNull @Valid Item> items) {
    public record Item(@NotNull @Positive Long returnItemId,
        @NotBlank @Pattern(regexp = "INTACT|DAMAGED") String condition) {}
}

