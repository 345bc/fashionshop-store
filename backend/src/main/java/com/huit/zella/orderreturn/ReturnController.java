package com.huit.zella.orderreturn;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.order.OrderController.NoteRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/order-return")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
public class ReturnController {
    private final ReturnService returnService;

    @GetMapping
    public ApiResponse<List<ReturnResponse>> list(@RequestParam Long orderId) {
        return ApiResponse.success(returnService.list(orderId));
    }
    @PostMapping
    public ResponseEntity<ApiResponse<ReturnResponse>> create(@Valid @RequestBody CreateReturnRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(returnService.create(request, actor.id())));
    }
    @PostMapping("/{id}/approve")
    public ApiResponse<ReturnResponse> approve(@PathVariable Long id, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.approve(id, actor.id()));
    }
    @PostMapping("/{id}/reject")
    public ApiResponse<ReturnResponse> reject(@PathVariable Long id, @Valid @RequestBody NoteRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.reject(id, request.note(), actor.id()));
    }
    @PostMapping("/{id}/cancel")
    public ApiResponse<ReturnResponse> cancel(@PathVariable Long id, @Valid @RequestBody NoteRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.cancel(id, request.note(), actor.id()));
    }
    @PostMapping("/{id}/receive")
    public ApiResponse<ReturnResponse> receive(@PathVariable Long id, @Valid @RequestBody ReceiveReturnRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.receive(id, request, actor.id()));
    }
    @PostMapping("/{id}/complete")
    public ApiResponse<ReturnResponse> complete(@PathVariable Long id, @Valid @RequestBody CompleteReturnRequest request,
            @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(returnService.complete(id, request, actor.id()));
    }
}

