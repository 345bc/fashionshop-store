package com.huit.zella.orderreturn;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.order.OrderController.NoteRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/order-return")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','CUSTOMER_SUPPORT','WAREHOUSE')")
public class ReturnController {
    private final ReturnService returnService;

    @GetMapping("/management")
    public ApiResponse<com.huit.zella.common.api.PageResponse<ReturnOrderSummaryResponse>> management(
            @RequestParam(defaultValue = "") @Size(max = 200) String q, @RequestParam(defaultValue = "ALL") @Size(max = 30) String status,
            @RequestParam(defaultValue = "0") @Min(0) int page, @RequestParam(defaultValue = "10") @Min(1) @Max(50) int size) {
        return ApiResponse.success(com.huit.zella.common.api.PageResponse.from(returnService.management(q, status,
                org.springframework.data.domain.PageRequest.of(page, size,
                        org.springframework.data.domain.Sort.by(org.springframework.data.domain.Sort.Direction.DESC, "id")))));
    }

    @GetMapping
    public ApiResponse<List<ReturnResponse>> list(@RequestParam @Positive Long orderId) {
        return ApiResponse.success(returnService.list(orderId));
    }
    @PreAuthorize("hasAnyRole('ADMIN','CUSTOMER_SUPPORT')")
    @PostMapping
    public ResponseEntity<ApiResponse<ReturnResponse>> create(@Valid @RequestBody CreateReturnRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(returnService.create(request, actor.id())));
    }
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{id}/approve")
    public ApiResponse<ReturnResponse> approve(@PathVariable @Positive Long id, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.approve(id, actor.id()));
    }
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{id}/reject")
    public ApiResponse<ReturnResponse> reject(@PathVariable @Positive Long id, @Valid @RequestBody NoteRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.reject(id, request.note(), actor.id()));
    }
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{id}/cancel")
    public ApiResponse<ReturnResponse> cancel(@PathVariable @Positive Long id, @Valid @RequestBody NoteRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.cancel(id, request.note(), actor.id()));
    }
    @PreAuthorize("hasAnyRole('ADMIN','WAREHOUSE')")
    @PostMapping("/{id}/receive")
    public ApiResponse<ReturnResponse> receive(@PathVariable @Positive Long id, @Valid @RequestBody ReceiveReturnRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.receive(id, request, actor.id()));
    }
    @PreAuthorize("hasRole('ADMIN')")
    @PostMapping("/{id}/complete")
    public ApiResponse<ReturnResponse> complete(@PathVariable @Positive Long id, @Valid @RequestBody CompleteReturnRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.complete(id, request, actor.id()));
    }
}

