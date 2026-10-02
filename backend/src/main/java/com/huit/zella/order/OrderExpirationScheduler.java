package com.huit.zella.order;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.time.Clock;
import java.time.LocalDateTime;

@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "app.order.expiration.enabled", havingValue = "true", matchIfMissing = true)
public class OrderExpirationScheduler {
    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final Clock orderClock;

    @Scheduled(fixedDelayString = "${app.order.expiration.interval-ms:1000}")
    public void expireOrders() {
        for (Long id : orderRepository.findExpiredOrderIds(LocalDateTime.now(orderClock), PageRequest.of(0, 100))) {
            try {
                orderService.expire(id);
            } catch (RuntimeException exception) {
                log.error("Could not expire order {}", id, exception);
            }
        }
    }
}

