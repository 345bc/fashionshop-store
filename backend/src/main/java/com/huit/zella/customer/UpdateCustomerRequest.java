package com.huit.zella.customer;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateCustomerRequest(
        @NotBlank @Size(max = 100) String fullName,
        @jakarta.validation.constraints.Pattern(regexp = "0[0-9]{9}", message = "Số điện thoại phải có 10 chữ số và bắt đầu bằng 0") String phone,
        String address,
        Boolean isActive
) {}
