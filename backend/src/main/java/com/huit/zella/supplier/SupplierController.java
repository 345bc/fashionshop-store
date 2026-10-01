package com.huit.zella.supplier;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/supplier")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SupplierController {
    SupplierService supplierService;

    @GetMapping
    public ApiResponse<List<SupplierResponse>> list(@RequestParam(required = false) String q) {
        return ApiResponse.success(supplierService.list(q));
    }

    @GetMapping("/{id}")
    public ApiResponse<SupplierResponse> get(@PathVariable Long id) {
        return ApiResponse.success(supplierService.get(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping
    public ResponseEntity<ApiResponse<SupplierResponse>> create(@Valid @RequestBody CreateSupplierRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(supplierService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<SupplierResponse> update(@PathVariable Long id, @Valid @RequestBody CreateSupplierRequest request) {
        return ApiResponse.success(supplierService.update(id, request));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        supplierService.delete(id);
        return ApiResponse.success(null);
    }
}
