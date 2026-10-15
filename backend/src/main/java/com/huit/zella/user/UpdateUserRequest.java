package com.huit.zella.user;

import com.huit.zella.enums.RoleEnum;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

import java.util.Set;

public record UpdateUserRequest(
        @NotBlank(message = "Username is required")
        @Size(max = 50, message = "Username must not exceed 50 characters")
        String username,

        @Size(min = 6, max = 50, message = "Mật khẩu phải từ 6 đến 50 ký tự")
        String password,

        @Email
        @NotBlank(message = "Email is required")
        @Size(max = 50, message = "Email must not exceed 100 characters")
        String email,

        @NotEmpty(message = "Roles are required")
        Set<RoleEnum> roles,

        boolean isActive
) {

}
