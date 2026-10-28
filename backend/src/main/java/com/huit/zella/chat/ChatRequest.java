package com.huit.zella.chat;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record ChatRequest(
        @NotBlank(message = "Vui lòng nhập tin nhắn")
        @Size(max = 1000, message = "Tin nhắn tối đa 1000 ký tự") String message,
        UUID conversationId
) {}
