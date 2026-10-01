package com.huit.zella.supplier;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateSupplierRequest(
        @NotBlank @Size(max = 150) String name,
        @Email @Size(max = 100) String contactEmail,
        @Size(max = 20) String phone,
        String address,
        @Size(max = 50) String code,
        @Size(max = 100) String contactPerson,
        Boolean isActive
) {}
