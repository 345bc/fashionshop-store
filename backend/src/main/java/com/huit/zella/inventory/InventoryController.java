package com.huit.zella.inventory;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/inventory")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
public class InventoryController {
    private final InventoryService service;

    @GetMapping
    public ApiResponse<List<InventoryResponse>> list(@RequestParam(required = false) String q,
                                                     @RequestParam(required = false) Long supplierId) {
        return ApiResponse.success(service.list(q, supplierId));
    }

    @GetMapping("/{id}/movements")
    public ApiResponse<List<InventoryMovementResponse>> history(@PathVariable Long id) {
        return ApiResponse.success(service.history(id));
    }

    @PostMapping("/adjustments")
    public ApiResponse<String> adjust(@Valid @RequestBody CreateInventoryAdjustmentRequest request,
                                      @AuthenticationPrincipal CurrentUser actor) {
        return ApiResponse.success(service.adjust(request, actor.id()));
    }
}
