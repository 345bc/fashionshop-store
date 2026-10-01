package com.huit.zella.customer;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateCustomerRequest(
        @NotBlank @Size(max = 100) String fullName,
        @Size(max = 20) String phone,
        String address,
        Boolean isActive
) {}
