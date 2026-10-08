package com.huit.zella.supplier;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateSupplierRequest(
        @NotBlank(message = "Supplier name is required")
        @Size(max = 150, message = "Supplier name must not exceed 150 characters")
        String name,

        @Email(message = "Email is not valid")
        @Size(max = 100, message = "Contact email must not exceed 100 characters")
        String contactEmail,

        @Size(max = 10, message = "Phone must not exceed 10 characters")
        String phone,

        String address,

        @Size(max = 50, message = "Code must not exceed 50 characters")
        String code,

        @Size(max = 100, message = "Contact person must not exceed 100 characters")
        String contactPerson,

        Boolean isActive
) {
}
