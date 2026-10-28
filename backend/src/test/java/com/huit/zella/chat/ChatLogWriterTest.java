package com.huit.zella.chat;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import java.util.List;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class ChatLogWriterTest {
    @Test void historyOutageDoesNotDiscardDeliveredAdvice() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        when(jdbc.update(anyString(), any(Object[].class))).thenThrow(new org.springframework.dao.DataAccessResourceFailureException("offline"));
        var response = new ChatResponse(UUID.randomUUID(), List.of(), true);
        assertDoesNotThrow(() -> new ChatLogWriter(jdbc).save(7L, "size", response, "ask_size"));
    }
}
