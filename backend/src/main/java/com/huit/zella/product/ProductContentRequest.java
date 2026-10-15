package com.huit.zella.product;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ProductContentRequest(@NotBlank @Size(max = 200) String name,
        @Size(max = 5000) String description, @Size(max = 50) String style,
        @Size(max = 100) String occasion) {}
