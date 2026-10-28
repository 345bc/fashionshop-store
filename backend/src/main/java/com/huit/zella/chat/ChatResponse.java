package com.huit.zella.chat;

import java.util.List;
import java.util.Map;
import java.util.UUID;

public record ChatResponse(UUID conversationId, List<Message> messages, boolean fallback) {
    public record Button(String title, String payload) {}
    public record Message(String text, String image, List<Button> buttons, Map<String, Object> custom) {}
}
