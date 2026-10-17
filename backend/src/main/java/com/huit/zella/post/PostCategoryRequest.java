package com.huit.zella.post;

import jakarta.validation.constraints.*;

public record PostCategoryRequest(
        @NotBlank @Size(max = 100) String name,
        boolean active,
        @Size(max = 500) @Pattern(regexp = "https?://[^\\s]+", message = "Ảnh phải là URL http hoặc https") String thumbnail) {
    public PostCategoryRequest(String name, boolean active) { this(name, active, null); }
}
