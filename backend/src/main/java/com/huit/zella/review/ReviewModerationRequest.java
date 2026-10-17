package com.huit.zella.review;

import jakarta.validation.constraints.*;

public record ReviewModerationRequest(
        @NotNull(message = "Vui lòng chọn trạng thái hiển thị") Boolean hidden,
        @NotBlank(message = "Vui lòng nhập lý do")
        @Size(max = 500, message = "Lý do tối đa 500 ký tự") String reason) {}
