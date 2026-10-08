package com.huit.zella.order;

import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageRequest;

import com.huit.zella.common.api.PageResponse;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/order")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
public class OrderController {
    private final OrderService orderService;
    public record NoteRequest(@NotBlank @Size(max = 400) String note) {}

    @GetMapping
    public ApiResponse<PageResponse<OrderResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(orderService.list(
                q, status,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }
    @GetMapping("/{id}")
    public ApiResponse<OrderResponse> get(@PathVariable Long id) { return ApiResponse.success(orderService.get(id)); }
    @PostMapping
    public ResponseEntity<ApiResponse<OrderResponse>> create(@Valid @RequestBody CreateOrderRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(orderService.create(request, actor.id())));
    }
    @PostMapping("/{id}/ship")
    public ApiResponse<OrderResponse> ship(@PathVariable Long id, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(orderService.ship(id, actor.id()));
    }
    @PostMapping("/{id}/deliver")
    public ApiResponse<OrderResponse> deliver(@PathVariable Long id, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(orderService.deliver(id, actor.id()));
    }
    @PostMapping("/{id}/cancel")
    public ApiResponse<OrderResponse> cancel(@PathVariable Long id, @Valid @RequestBody NoteRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(orderService.cancel(id, request.note(), actor.id()));
    }
    @PostMapping("/{id}/refunded")
    public ApiResponse<OrderResponse> refunded(@PathVariable Long id, @Valid @RequestBody NoteRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(orderService.refunded(id, request.note(), actor.id()));
    }
}
