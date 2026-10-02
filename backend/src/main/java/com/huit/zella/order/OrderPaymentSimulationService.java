package com.huit.zella.order;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// BEGIN TEMP_ORDER_PAYMENT_SIMULATION
// Temporary test helper. Delete this file when a real payment gateway is integrated.
// Disable without deleting code: app.order.payment-simulation.enabled=false.
@Service
@Profile("local")
@ConditionalOnProperty(name = "app.order.payment-simulation.enabled", havingValue = "true", matchIfMissing = true)
@RequiredArgsConstructor
public class OrderPaymentSimulationService {
    private final OrderService orderService;

    @Transactional
    public OrderResponse confirmForTesting(Long id) {
        Order order = orderService.lock(id);
        // Use the real online-payment workflow, including the 5-minute deadline and idempotency.
        return orderService.recordOnlinePayment(id, order.getTotalAmount(), "SIMULATED-ORDER-" + id);
    }
}
// END TEMP_ORDER_PAYMENT_SIMULATION

