package com.huit.zella.chat;

import com.huit.zella.auth.UserService;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/chat")
public class ChatController {
    private final ChatService chat;
    private final UserService users;

    public ChatController(ChatService chat, UserService users) {
        this.chat = chat;
        this.users = users;
    }

    @PostMapping("/messages")
    public ResponseEntity<ApiResponse<ChatResponse>> send(@Valid @RequestBody ChatRequest request, Authentication authentication) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .body(ApiResponse.success(chat.send(users.current(authentication).id(), request)));
    }
}
