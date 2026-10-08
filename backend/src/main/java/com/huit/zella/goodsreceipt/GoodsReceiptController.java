package com.huit.zella.goodsreceipt;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

import com.huit.zella.common.api.PageResponse;
import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/goods-receipt") @RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
public class GoodsReceiptController {
    private final GoodsReceiptService service;
    @PostMapping("/{id}/returns")
    public ApiResponse<GoodsReceiptResponse> returnToSupplier(@PathVariable Long id,
            @Valid @RequestBody CreateSupplierReturnRequest request, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(service.returnToSupplier(id, request, actor.id()));
    }
    @PostMapping("/{id}/refunds")
    public ApiResponse<GoodsReceiptResponse> supplierRefund(@PathVariable Long id,
            @Valid @RequestBody CreateSupplierPaymentRequest request, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(service.supplierRefund(id, request, actor.id()));
    }

    @GetMapping
    public ApiResponse<PageResponse<GoodsReceiptResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(service.list(
                q, status,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }

    @GetMapping("/{id}") public ApiResponse<GoodsReceiptResponse> get(@PathVariable Long id) { return ApiResponse.success(service.get(id)); }
    @PostMapping public ResponseEntity<ApiResponse<GoodsReceiptResponse>> create(@Valid @RequestBody CreateGoodsReceiptRequest request,
        @AuthenticationPrincipal CurrentUser actor) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(service.create(request, actor.id())));
    }
    @PutMapping("/{id}") public ApiResponse<GoodsReceiptResponse> update(@PathVariable Long id,
        @Valid @RequestBody CreateGoodsReceiptRequest request) { return ApiResponse.success(service.update(id, request)); }
    @PostMapping("/{id}/post") public ApiResponse<GoodsReceiptResponse> post(@PathVariable Long id,
        @AuthenticationPrincipal CurrentUser actor) { return ApiResponse.success(service.post(id, actor.id())); }
    @PostMapping("/{id}/cancel") public ApiResponse<GoodsReceiptResponse> cancel(@PathVariable Long id,
        @AuthenticationPrincipal CurrentUser actor) { return ApiResponse.success(service.cancel(id, actor.id())); }
    @PostMapping("/{id}/payments") public ApiResponse<GoodsReceiptResponse> pay(@PathVariable Long id,
        @Valid @RequestBody CreateSupplierPaymentRequest request, @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(service.pay(id, request, actor.id()));
    }
}
