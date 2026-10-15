package com.huit.zella.staff;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.data.domain.*;

@RestController
@RequestMapping("/api/v1/staff")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class StaffController {
    private final StaffService service;

    @GetMapping
    public ApiResponse<Page<StaffResponse>> list(@RequestParam(required = false) String q, @RequestParam(required = false) Boolean active, Pageable pageable) {
        return ApiResponse.success(service.list(q, active, pageable));
    }

    @PostMapping
    public ApiResponse<StaffResponse> create(@Valid @RequestBody CreateStaffRequest req) {
        return ApiResponse.success(service.create(req));
    }

    @PutMapping("/{id}")
    public ApiResponse<StaffResponse> update(@PathVariable Long id, @Valid @RequestBody StaffRequest req) {
        return ApiResponse.success(service.update(id, req));
    }

}
