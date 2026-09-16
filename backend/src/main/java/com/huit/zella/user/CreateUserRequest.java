package com.huit.zella.user;

import com.huit.zella.auth.Role;
import com.huit.zella.enums.RoleEnum;
import jakarta.persistence.Column;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.Set;

public record CreateUserRequest(
        @NotBlank(message = "Username is required")
        @Size(max = 50, message = "Username must not exceed 50 characters")
        String username,

        @NotBlank(message = "Password is required")
        @Size(max = 50, message = "Password must not exceed 50 characters")
        String password,

        @Email
        @NotBlank(message = "Email is required")
        @Size(max = 50, message = "Email must not exceed 100 characters")
        String email,

        @NotEmpty(message = "Roles are required")
        Set<RoleEnum> roles
) {
}
