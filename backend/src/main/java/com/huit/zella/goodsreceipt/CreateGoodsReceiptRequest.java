package com.huit.zella.goodsreceipt;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

import java.math.BigDecimal;
import java.util.List;

public record CreateGoodsReceiptRequest(
        @NotNull Long supplierId,
        @Size(max = 500) String note,
        @NotEmpty @Size(max = 200) List<@Valid Item> items
) {
    public record Item(@NotNull Long variantId, @NotNull @Min(1) Integer quantity,
                       @NotNull @DecimalMin("0") @Digits(integer = 16, fraction = 2) BigDecimal unitCost) {
    }
}
