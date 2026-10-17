package com.huit.zella.payment.vnpay;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.order.OrderController.NoteRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Positive;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequiredArgsConstructor @PreAuthorize("hasRole('ADMIN')")
public class VnPayRefundController {
    private final VnPayRefundService service;

    @PostMapping("/api/v1/order/{id}/vnpay-refund")
    public ApiResponse<VnPayRefundService.RefundView> refundOrder(@PathVariable @Positive Long id,
            @Valid @RequestBody NoteRequest request, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(service.submit(id, null, request.note(), actor.id()));
    }
    @PostMapping("/api/v1/order-return/{id}/vnpay-refund")
    public ApiResponse<VnPayRefundService.RefundView> refundReturn(@PathVariable @Positive Long id,
            @Valid @RequestBody NoteRequest request, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(service.submit(null, id, request.note(), actor.id()));
    }
    @GetMapping("/api/v1/order/{id}/vnpay-refunds")
    public ApiResponse<List<VnPayRefundService.RefundView>> list(@PathVariable @Positive Long id) {
        return ApiResponse.success(service.list(id));
    }
    @PostMapping("/api/v1/payment/vnpay/refunds/{id}/reconcile")
    public ApiResponse<VnPayRefundService.RefundView> reconcile(@PathVariable @Positive Long id) {
        return ApiResponse.success(service.reconcile(id));
    }
}
