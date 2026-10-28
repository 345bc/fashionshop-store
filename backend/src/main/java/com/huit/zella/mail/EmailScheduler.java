package com.huit.zella.mail;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.Instant;

@Component @RequiredArgsConstructor @Slf4j
@ConditionalOnProperty(name = "app.mail.enabled", havingValue = "true")
public class EmailScheduler {
    private final EmailOutboxRepository repository;
    private final EmailDelivery delivery;

    @Scheduled(fixedDelayString = "${app.mail.interval-ms:5000}")
    public void sendPending() {
        for (Long id : repository.pending(Instant.now(), PageRequest.of(0, 20))) {
            try { delivery.deliver(id); }
            catch (RuntimeException failure) { log.error("Email {} delivery transaction failed ({})", id, failure.getClass().getSimpleName()); }
        }
    }
}
