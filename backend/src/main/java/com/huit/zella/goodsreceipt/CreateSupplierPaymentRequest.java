package com.huit.zella.goodsreceipt;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
public record CreateSupplierPaymentRequest(
    @NotNull @DecimalMin(value = "0", inclusive = false) @Digits(integer = 16, fraction = 2) BigDecimal amount,
    @NotBlank @Pattern(regexp = "CASH|BANK_TRANSFER") String paymentMethod,
    @Size(max = 500) String note
) {}
