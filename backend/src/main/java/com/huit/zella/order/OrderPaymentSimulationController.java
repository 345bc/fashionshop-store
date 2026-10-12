package com.huit.zella.order;

import com.huit.zella.common.api.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

// BEGIN TEMP_ORDER_PAYMENT_SIMULATION
// Temporary local-only API. Delete alongside OrderPaymentSimulationService after testing.
// This is not a gateway callback and is never available on a non-local profile.
@RestController
@RequestMapping("/api/v1/order-test")
@Profile("local")
@ConditionalOnProperty(name = "app.order.payment-simulation.enabled", havingValue = "true", matchIfMissing = true)
@PreAuthorize("hasRole('ADMIN')")
@RequiredArgsConstructor
public class OrderPaymentSimulationController {
    private final OrderPaymentSimulationService simulationService;

    @GetMapping("/enabled")
    public ApiResponse<Boolean> enabled() {
        return ApiResponse.success(true);
    }

    @PostMapping("/{id}/confirm")
    public ApiResponse<OrderResponse> confirm(@PathVariable Long id) {
        return ApiResponse.success(simulationService.confirmForTesting(id));
    }
}
// END TEMP_ORDER_PAYMENT_SIMULATION

