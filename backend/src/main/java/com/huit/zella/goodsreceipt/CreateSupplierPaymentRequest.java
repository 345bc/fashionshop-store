package com.huit.zella.goodsreceipt;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
public record CreateSupplierPaymentRequest(
    @NotNull(message = "Amount is required")
    @DecimalMin(value = "0", inclusive = false, message = "Amount must be strictly greater than 0")
    @Digits(integer = 16, fraction = 2, message = "Amount must have up to 16 digits and 2 decimals")
    BigDecimal amount,

    @NotBlank(message = "Payment method is required")
    @Pattern(regexp = "CASH|BANK_TRANSFER", message = "Payment method must be CASH or BANK_TRANSFER")
    String paymentMethod,

    @Size(max = 500, message = "Note must not exceed 500 characters")
    String note
) {}
