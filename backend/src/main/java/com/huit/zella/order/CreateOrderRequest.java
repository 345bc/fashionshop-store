package com.huit.zella.order;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.util.List;

public record CreateOrderRequest(
    Long customerUserId,
    @NotBlank @Size(max = 150) String recipientName,
    @NotBlank @Pattern(regexp = "0[0-9]{9}", message = "Số điện thoại phải có 10 chữ số và bắt đầu bằng 0") String recipientPhone,
    @NotBlank @Size(max = 350) String address,
    @Size(max = 500) String note,
    @NotNull @DecimalMin("0") @Digits(integer = 16, fraction = 2) BigDecimal shippingFee,
    @NotBlank @Pattern(regexp = "ONLINE") String paymentMethod,
    @NotEmpty @Size(max = 200) List<@Valid Item> items
) {
    public record Item(@NotNull Long variantId, @NotNull @Positive Integer quantity) {}
}
