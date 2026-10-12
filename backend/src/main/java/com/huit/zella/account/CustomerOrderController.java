package com.huit.zella.account;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.*;
import com.huit.zella.cart.CartResponse;
import com.huit.zella.orderreturn.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/me/orders") @RequiredArgsConstructor
public class CustomerOrderController {
    private final CustomerOrderService service;
    public record ReorderRequest(@NotBlank @Pattern(regexp = "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89aAbB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}") String key) {}
    @GetMapping public ApiResponse<PageResponse<CustomerOrderResponse>> list(@AuthenticationPrincipal CurrentUser user,
            @RequestParam(required = false) String status, @RequestParam(defaultValue = "false") boolean purchases,
            @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "10") int size) {
        return ApiResponse.success(PageResponse.from(service.list(user.id(), status, purchases, PageRequest.of(Math.max(0, page), Math.clamp(size, 1, 50), Sort.by(Sort.Direction.DESC, "id")))));
    }
    @GetMapping("/{id}") public ApiResponse<CustomerOrderResponse> get(@PathVariable Long id, @AuthenticationPrincipal CurrentUser user) { return ApiResponse.success(service.get(id, user.id())); }
    @PostMapping("/{id}/cancel") public ApiResponse<CustomerOrderResponse> cancel(@PathVariable Long id, @AuthenticationPrincipal CurrentUser user) { return ApiResponse.success(service.cancel(id, user.id())); }
    @PostMapping("/{id}/reorder") public ApiResponse<CartResponse> reorder(@PathVariable Long id, @AuthenticationPrincipal CurrentUser user, @Valid @RequestBody ReorderRequest request) { return ApiResponse.success(service.reorder(id, user.id(), request.key())); }
    @PostMapping("/{id}/returns") public ApiResponse<ReturnResponse> returnItems(@PathVariable Long id, @AuthenticationPrincipal CurrentUser user, @Valid @RequestBody CreateReturnRequest request) { return ApiResponse.success(service.requestReturn(id, user.id(), request)); }
    @PutMapping("/{id}/items/{itemId}/review") public ApiResponse<CustomerOrderResponse.Review> review(@PathVariable Long id, @PathVariable Long itemId, @AuthenticationPrincipal CurrentUser user, @Valid @RequestBody CustomerOrderService.ReviewRequest request) { return ApiResponse.success(service.review(id, itemId, user.id(), request)); }
}
