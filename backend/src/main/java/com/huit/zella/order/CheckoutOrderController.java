package com.huit.zella.order;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/checkout/orders")
@RequiredArgsConstructor
public class CheckoutOrderController {
    private final OrderService orderService;

    @PostMapping
    public ResponseEntity<ApiResponse<CheckoutOrderResponse>> create(
            @Valid @RequestBody CreateCheckoutOrderRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(orderService.createCheckout(request, actor == null ? null : actor.id())));
    }

    @GetMapping("/{code}")
    public ApiResponse<CheckoutOrderResponse> status(@PathVariable String code,
            @RequestHeader("X-Checkout-Token") String token) {
        return ApiResponse.success(orderService.checkoutStatus(code, token));
    }
}

