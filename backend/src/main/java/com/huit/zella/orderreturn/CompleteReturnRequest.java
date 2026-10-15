package com.huit.zella.orderreturn;

import jakarta.validation.constraints.*;

public record CompleteReturnRequest(
    @NotBlank @Pattern(regexp = "CASH|BANK_TRANSFER|NO_REFUND") String refundMethod,
    @NotBlank @Size(max = 400) String note) {}
