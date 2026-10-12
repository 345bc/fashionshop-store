package com.huit.zella.cart;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/cart")
@RequiredArgsConstructor
public class CartController {
    private final CartService cartService;
    @GetMapping
    public ApiResponse<CartResponse> get(@AuthenticationPrincipal CurrentUser user) { return ApiResponse.success(cartService.get(user.id())); }
    @PostMapping("/quote")
    public ApiResponse<CartResponse> quote(@Valid @RequestBody CartQuoteRequest request) { return ApiResponse.success(cartService.quote(request.items())); }
    @PostMapping("/items")
    public ApiResponse<CartResponse> add(@AuthenticationPrincipal CurrentUser user, @Valid @RequestBody CartItemRequest request) { return ApiResponse.success(cartService.add(user.id(), request)); }
    public record QuantityRequest(@NotNull @Min(1) @Max(999) Integer quantity) {}
    @PatchMapping("/items/{variantId}")
    public ApiResponse<CartResponse> update(@AuthenticationPrincipal CurrentUser user, @PathVariable Long variantId, @Valid @RequestBody QuantityRequest request) { return ApiResponse.success(cartService.update(user.id(), variantId, request.quantity())); }
    @DeleteMapping("/items/{variantId}")
    public ApiResponse<CartResponse> remove(@AuthenticationPrincipal CurrentUser user, @PathVariable Long variantId) { return ApiResponse.success(cartService.remove(user.id(), variantId)); }
    @PutMapping("/items/{variantId}")
    public ApiResponse<CartResponse> replace(@AuthenticationPrincipal CurrentUser user, @PathVariable Long variantId, @Valid @RequestBody CartItemRequest request) { return ApiResponse.success(cartService.replace(user.id(), variantId, request)); }
    @DeleteMapping("/items")
    public ApiResponse<CartResponse> clear(@AuthenticationPrincipal CurrentUser user) { return ApiResponse.success(cartService.remove(user.id(), null)); }
    @PostMapping("/merge")
    public ApiResponse<CartResponse> merge(@AuthenticationPrincipal CurrentUser user, @Valid @RequestBody MergeCartRequest request) { return ApiResponse.success(cartService.merge(user.id(), request)); }
}
