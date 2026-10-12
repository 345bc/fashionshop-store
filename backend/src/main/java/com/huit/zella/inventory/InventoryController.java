package com.huit.zella.inventory;

import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import com.huit.zella.common.api.PageResponse;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/inventory")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
public class InventoryController {
    private final InventoryService service;

    @GetMapping
    public ApiResponse<PageResponse<InventoryResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Long supplierId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(service.list(
                q, supplierId, status,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }

    @GetMapping("/movements")
    public ApiResponse<PageResponse<InventoryMovementResponse>> history(
            @RequestParam Long variantId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(service.history(
                variantId,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }

    @PostMapping("/adjustments")
    public ApiResponse<String> adjust(@Valid @RequestBody CreateInventoryAdjustmentRequest request,
                                      @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(service.adjust(request, actor.id()));
    }
}
