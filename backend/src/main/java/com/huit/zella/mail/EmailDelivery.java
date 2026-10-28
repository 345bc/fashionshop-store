package com.huit.zella.mail;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.MailException;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;

@Service
@Slf4j
public class EmailDelivery {
    private final EmailOutboxRepository repository;
    private final JavaMailSender sender;
    private final String from;

    public EmailDelivery(EmailOutboxRepository repository, JavaMailSender sender,
                         @Value("${spring.mail.username:}") String from) {
        this.repository = repository;
        this.sender = sender;
        this.from = from;
    }

    @Transactional
    public void deliver(Long id) {
        QueuedEmail email = repository.lock(id).orElse(null);
        Instant now = Instant.now();
        if (email == null || email.getAttempts() >= 8 || email.getNextAttemptAt().isAfter(now)) return;
        if (email.getExpiresAt() != null && !email.getExpiresAt().isAfter(now)) {
            repository.delete(email);
            return;
        }
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(from);
        message.setTo(email.getRecipient());
        message.setSubject(email.getSubject());
        message.setText(email.getBody());
        try {
            if (email.getHtmlBody() == null || email.getHtmlBody().isBlank()) {
                sender.send(message);
            } else {
                var mime = sender.createMimeMessage();
                try {
                    var helper = new org.springframework.mail.javamail.MimeMessageHelper(mime, true, "UTF-8");
                    helper.setFrom(from, "ZELLA");
                    helper.setTo(email.getRecipient());
                    helper.setSubject(email.getSubject());
                    helper.setText(email.getBody(), email.getHtmlBody());
                } catch (jakarta.mail.MessagingException | java.io.UnsupportedEncodingException invalid) {
                    throw new org.springframework.mail.MailParseException("Could not prepare HTML email", invalid);
                }
                sender.send(mime);
            }
            repository.delete(email);
        } catch (MailException failure) {
            email.setAttempts(email.getAttempts() + 1);
            email.setNextAttemptAt(now.plusSeconds(Math.min(3600, 30L << email.getAttempts())));
            // Do not log recipient, reset links, credentials, or provider exception bodies.
            log.warn("Email {} failed, attempt {} of 8 ({})", id, email.getAttempts(), failure.getClass().getSimpleName());
            if (email.getAttempts() == 8) {
                // Discard sensitive reset links after the final failed attempt.
                email.setBody("");
                email.setHtmlBody(null);
                log.error("Email {} exhausted delivery attempts; check Gmail configuration", id);
            }
        }
    }
}
