package com.huit.zella.staff;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

@com.fasterxml.jackson.annotation.JsonIgnoreProperties(ignoreUnknown = true)
public record CreateStaffRequest(
    @NotBlank @Size(max = 100) String fullName,
    @Size(max = 100) String position,
    @NotBlank(message = "Số điện thoại là bắt buộc")
        @Pattern(regexp = "^0[0-9]{9}$", message = "Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0") String phone,
    @NotNull @PastOrPresent LocalDate hiredDate,
    @NotBlank @Size(max = 50) String username,
    @NotBlank @Email @Size(max = 100) String email,
    @NotBlank @Size(min = 6, max = 50) String password
) {}
