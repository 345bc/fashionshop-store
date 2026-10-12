package com.huit.zella.order;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record OrderLookupRequest(
        @NotBlank @Size(max = 32) String code,
        @NotBlank @Pattern(regexp = "0[0-9]{9}", message = "Số điện thoại phải có 10 chữ số và bắt đầu bằng 0") String phone
) {}
