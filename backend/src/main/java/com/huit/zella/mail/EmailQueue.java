package com.huit.zella.mail;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
public class EmailQueue {
    private final EmailOutboxRepository repository;
    private final boolean enabled;

    public EmailQueue(EmailOutboxRepository repository, @Value("${app.mail.enabled:false}") boolean enabled) {
        this.repository = repository;
        this.enabled = enabled;
    }

    public boolean enabled() {
        return enabled;
    }

    @Transactional
    public void enqueue(String recipient, String subject, String body, Instant expiresAt) {
        enqueueHtml(recipient, subject, body, null, expiresAt);
    }

    @Transactional
    public void enqueueHtml(String recipient, String subject, String body, String htmlBody, Instant expiresAt) {
        if (!enabled || recipient == null || recipient.isBlank()) return;
        QueuedEmail email = new QueuedEmail();
        email.setRecipient(recipient);
        email.setSubject(subject);
        email.setBody(body);
        email.setHtmlBody(htmlBody);
        email.setNextAttemptAt(Instant.now());
        email.setExpiresAt(expiresAt);
        repository.save(email);
    }
}
