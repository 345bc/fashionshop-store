package com.huit.zella.staff;

import jakarta.validation.constraints.*;
import java.time.LocalDate;

@com.fasterxml.jackson.annotation.JsonIgnoreProperties(ignoreUnknown = true)
public record StaffRequest(
    @NotBlank @Size(max = 100) String fullName,
    @Size(max = 100) String position,
    @NotBlank(message = "Số điện thoại là bắt buộc")
    @Pattern(regexp = "^0[0-9]{9}$", message = "Số điện thoại phải gồm 10 chữ số và bắt đầu bằng 0") String phone,
    @NotNull @PastOrPresent LocalDate hiredDate
) {}
