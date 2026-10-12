package com.huit.zella.inventory;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
public record CreateInventoryAdjustmentRequest(@NotBlank @Size(max = 500) String reason,
    @NotEmpty @Size(max = 200) List<@Valid Item> items) {
    public record Item(@NotNull Long variantId, @NotNull @Min(0) Integer expectedQuantity,
        @NotNull @Min(0) Integer countedQuantity) {}
}
