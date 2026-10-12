package com.huit.zella.order;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.cart.CartItemRequest;
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
    private final com.huit.zella.payment.vnpay.VnPayService vnPayService;
    private final com.huit.zella.voucher.VoucherService vouchers;
    private final com.huit.zella.cart.CartService cart;

    public record VoucherRequest(
            @jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Size(max=50) String code,
            @jakarta.validation.constraints.NotEmpty @jakarta.validation.constraints.Size(max=200)
            java.util.List<@jakarta.validation.constraints.NotNull @Valid CartItemRequest> items) {}
    @PostMapping("/voucher")
    public ApiResponse<CheckoutPriceResponse> quoteVoucher(@Valid @RequestBody VoucherRequest request,
            @AuthenticationPrincipal CurrentUser user) {
        return ApiResponse.success(vouchers.quote(request.items(),user==null?null:user.id(),request.code(),cart));
    }
    public record QuoteRequest(
            @jakarta.validation.constraints.Size(max=50) String voucherCode,
            @jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Pattern(regexp="STANDARD|EXPRESS") String shippingMethod,
            @jakarta.validation.constraints.NotEmpty @jakarta.validation.constraints.Size(max=200)
            java.util.List<@jakarta.validation.constraints.NotNull @Valid CartItemRequest> items) {}
    @PostMapping("/quote") public ApiResponse<CheckoutPriceResponse> quote(@Valid @RequestBody QuoteRequest request,@AuthenticationPrincipal CurrentUser user) {
        return ApiResponse.success(vouchers.quote(request.items(),user==null?null:user.id(),request.voucherCode(),request.shippingMethod(),cart));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CheckoutOrderResponse>> create(
            @Valid @RequestBody CreateCheckoutOrderRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        vnPayService.ensureConfigured();
        return ResponseEntity.status(HttpStatus.CREATED)
            .body(ApiResponse.success(orderService.createCheckout(request, actor == null ? null : actor.id())));
    }

    @PostMapping("/lookup")
    public ResponseEntity<ApiResponse<OrderLookupResponse>> lookup(@Valid @RequestBody OrderLookupRequest request) {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(ApiResponse.success(orderService.lookup(request)));
    }

    @GetMapping("/{code}")
    public ApiResponse<CheckoutOrderResponse> status(@PathVariable String code,
            @RequestHeader("X-Checkout-Token") String token) {
        return ApiResponse.success(orderService.checkoutStatus(code, token));
    }

    @PostMapping("/{code}/cancel")
    public ApiResponse<CheckoutOrderResponse> cancel(@PathVariable String code,
            @RequestHeader("X-Checkout-Token") String token) {
        return ApiResponse.success(orderService.cancelCheckout(code, token));
    }
}

