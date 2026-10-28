package com.huit.zella.chat;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.auth.UserService;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class ChatControllerTest {
    final ChatService chat = mock(ChatService.class);
    final UserService users = mock(UserService.class);
    final CurrentUser user = new CurrentUser(7L, "buyer@example.test", "buyer", List.of("USER"));
    final UsernamePasswordAuthenticationToken auth = UsernamePasswordAuthenticationToken.authenticated(user, null, List.of());
    MockMvc mvc;

    @BeforeEach void setup() {
        mvc = MockMvcBuilders.standaloneSetup(new ChatController(chat, users))
                .setControllerAdvice(new GlobalExceptionHandler()).build();
        when(users.current(auth)).thenReturn(user);
    }

    @Test void serializesApiEnvelopeCatalogAndOpaqueConversationId() throws Exception {
        UUID id = UUID.randomUUID();
        when(chat.send(eq(7L), any())).thenReturn(new ChatResponse(id, List.of(new ChatResponse.Message("Tìm thấy áo", null, List.of(),
                Map.of("type", "products", "products", List.of(Map.of("slug", "ao-thun", "price", 195000))))), false));
        mvc.perform(post("/api/v1/chat/messages").principal(auth).contentType(MediaType.APPLICATION_JSON).content("{\"message\":\"Tìm áo\"}"))
                .andExpect(status().isOk()).andExpect(header().string("Cache-Control", "no-store"))
                .andExpect(jsonPath("$.data.conversationId").value(id.toString()))
                .andExpect(jsonPath("$.data.messages[0].custom.products[0].price").value(195000))
                .andExpect(jsonPath("$.data.messages[0].recipient_id").doesNotExist());
    }

    @Test void rejectsMissingTextAndMalformedConversationIdsBeforeCallingModel() throws Exception {
        for (String invalid : List.of("{\"message\":\" \"}", "{\"message\":\"Hi\",\"conversationId\":\"not-a-uuid\"}")) {
            mvc.perform(post("/api/v1/chat/messages").principal(auth).contentType(MediaType.APPLICATION_JSON).content(invalid))
                    .andExpect(status().isBadRequest());
        }
        verifyNoInteractions(chat);
    }

    @Test void anonymousRequestCannotReachTheChatService() throws Exception {
        when(users.current(null)).thenThrow(new BusinessException(org.springframework.http.HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Bạn chưa đăng nhập"));
        mvc.perform(post("/api/v1/chat/messages").contentType(MediaType.APPLICATION_JSON).content("{\"message\":\"Hi\"}"))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(chat);
    }
}
