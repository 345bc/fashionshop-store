package com.huit.zella.post;

import jakarta.validation.constraints.*;

import java.time.Instant;

public record PostRequest(
        @NotNull Long categoryId,
        @NotBlank @Size(max = 255) String title,
        @Size(max = 500) String summary,
        @NotBlank @Size(max = 500) @Pattern(regexp = "https?://[^\\s]+", message = "Ảnh phải là URL http hoặc https") String thumbnail,
        @NotBlank @Size(max = 100000) String content,
        @NotNull PostStatus status, Instant publishedAt) {
}
