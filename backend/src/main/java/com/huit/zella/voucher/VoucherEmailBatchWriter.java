package com.huit.zella.voucher;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import java.sql.Timestamp;
import java.time.Instant;
import java.util.*;

@Component @RequiredArgsConstructor
public class VoucherEmailBatchWriter {
    private final JdbcTemplate jdbc;
    public record Message(String email, String tier, String subject, String body, Instant scheduledAt, Instant expiresAt) {}

    // JPA's SQL Server IDENTITY inserts execute one by one. JDBC batches avoid that round trip per customer.
    // Both tables participate in the caller's transaction on the same DataSource.
    @Transactional(propagation = Propagation.MANDATORY)
    public void enqueue(Long voucherId, Instant queuedAt, List<Message> messages) {
        if (messages.isEmpty()) return;
        Calendar utc = Calendar.getInstance(TimeZone.getTimeZone("UTC"));
        jdbc.batchUpdate("insert into voucher_email_recipients (voucher_id, email, membership_tier, queued_at) values (?, ?, ?, ?)",
                messages, 500, (statement, message) -> {
                    statement.setLong(1, voucherId); statement.setString(2, message.email());
                    statement.setString(3, message.tier()); statement.setTimestamp(4, Timestamp.from(queuedAt), utc);
                });
        jdbc.batchUpdate("insert into email_outbox (recipient, subject, body, attempts, next_attempt_at, expires_at) values (?, ?, ?, 0, ?, ?)",
                messages, 500, (statement, message) -> {
                    statement.setString(1, message.email()); statement.setNString(2, message.subject());
                    statement.setNString(3, message.body());
                    statement.setTimestamp(4, Timestamp.from(message.scheduledAt()), utc);
                    statement.setTimestamp(5, Timestamp.from(message.expiresAt()), utc);
                });
    }
}
