package com.huit.zella.chat;

import com.huit.zella.common.exception.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Semaphore;

@Service
public class ChatService {
    private final RasaClient rasa;
    private final ChatLogWriter history;
    private final Semaphore capacity = new Semaphore(8);
    private final Set<String> inFlight = ConcurrentHashMap.newKeySet();

    public ChatService(RasaClient rasa, ChatLogWriter history) {
        this.rasa = rasa;
        this.history = history;
    }

    public ChatResponse send(Long userId, ChatRequest request) {
        if (userId == null || userId <= 0) {
            throw new BusinessException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Bạn cần đăng nhập để trò chuyện.");
        }
        if (request.message() == null || request.message().isBlank() || request.message().length() > 1000) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_CHAT_MESSAGE", "Tin nhắn cần có nội dung và tối đa 1000 ký tự.");
        }
        UUID conversationId = request.conversationId() == null ? UUID.randomUUID() : request.conversationId();
        // User ownership is imposed here, never accepted from a caller-supplied sender or userId.
        String sender = "zella-" + userId + "-" + conversationId;
        if (!inFlight.add(sender)) throw busy();
        if (!capacity.tryAcquire()) {
            inFlight.remove(sender);
            throw busy();
        }
        try {
            String message = request.message().strip();
            var result = rasa.send(sender, message);
            var response = new ChatResponse(conversationId, result.messages(), result.fallback());
            history.save(userId, message, response, result.intent());
            return response;
        } finally {
            capacity.release();
            inFlight.remove(sender);
        }
    }

    private static BusinessException busy() {
        return new BusinessException(HttpStatus.TOO_MANY_REQUESTS, "CHAT_BUSY", "Trợ lý đang xử lý tin nhắn. Bạn đợi một chút rồi thử lại nhé.");
    }
}
