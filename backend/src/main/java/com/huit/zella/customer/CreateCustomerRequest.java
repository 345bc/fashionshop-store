package com.huit.zella.customer;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateCustomerRequest(
        @NotBlank @Email String email,
        @NotBlank @Size(max = 50) String username,
        @NotBlank @Size(min = 8) String password,
        @NotBlank @Size(max = 100) String fullName,
        @Size(max = 20) String phone,
        String address
) {}
