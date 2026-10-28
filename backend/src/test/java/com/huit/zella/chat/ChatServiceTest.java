package com.huit.zella.chat;

import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ChatServiceTest {
    final RasaClient rasa = mock(RasaClient.class);
    final ChatLogWriter history = mock(ChatLogWriter.class);
    final ChatService service = new ChatService(rasa, history);
    final RasaClient.Result result = new RasaClient.Result(List.of(new ChatResponse.Message("Xin chào", null, List.of(), null)), "greet", false);

    @Test void createsConversationAndWritesAuthenticatedUserHistory() {
        when(rasa.send(anyString(), anyString())).thenReturn(result);
        ChatResponse response = service.send(7L, new ChatRequest("  Xin chào  ", null));
        assertNotNull(response.conversationId());
        verify(rasa).send("zella-7-" + response.conversationId(), "Xin chào");
        verify(history).save(7L, "Xin chào", response, "greet");
    }

    @Test void identicalConversationIdsAreIsolatedBetweenAccounts() {
        when(rasa.send(anyString(), anyString())).thenReturn(result);
        UUID id = UUID.randomUUID();
        service.send(7L, new ChatRequest("Hi", id));
        service.send(9L, new ChatRequest("Hi", id));
        var senders = ArgumentCaptor.forClass(String.class);
        verify(rasa, times(2)).send(senders.capture(), eq("Hi"));
        assertNotEquals(senders.getAllValues().get(0), senders.getAllValues().get(1));
    }

    @Test void rejectsAnonymousBlankAndOversizedMessagesBeforeAnyModelCall() {
        assertThrows(BusinessException.class, () -> service.send(null, new ChatRequest("Hi", null)));
        assertThrows(BusinessException.class, () -> service.send(7L, new ChatRequest(" ", null)));
        assertThrows(BusinessException.class, () -> service.send(7L, new ChatRequest("x".repeat(1001), null)));
        verifyNoInteractions(rasa, history);
    }

    @Test void rejectsOverlappingTurnsAndReleasesConversationAfterModelFailure() throws Exception {
        UUID id = UUID.randomUUID();
        CountDownLatch entered = new CountDownLatch(1);
        CountDownLatch release = new CountDownLatch(1);
        when(rasa.send(anyString(), anyString())).thenAnswer(invocation -> {
            entered.countDown();
            if (!release.await(5, TimeUnit.SECONDS)) throw new IllegalStateException("test timed out");
            throw new BusinessException(org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE, "CHAT_UNAVAILABLE", "offline");
        });
        try (var executor = Executors.newSingleThreadExecutor()) {
            var running = executor.submit(() -> assertThrows(BusinessException.class, () -> service.send(7L, new ChatRequest("First", id))));
            assertTrue(entered.await(5, TimeUnit.SECONDS));
            try {
                var busy = assertThrows(BusinessException.class, () -> service.send(7L, new ChatRequest("Second", id)));
                assertEquals("CHAT_BUSY", busy.getCode());
            } finally { release.countDown(); }
            running.get(5, TimeUnit.SECONDS);
        }
        reset(rasa);
        when(rasa.send(anyString(), anyString())).thenReturn(result);
        assertDoesNotThrow(() -> service.send(7L, new ChatRequest("Retry", id)));
    }
}
