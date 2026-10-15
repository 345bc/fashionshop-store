package com.huit.zella.dashboard;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController @RequestMapping("/api/v1/dashboard") @RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class DashboardController {
    private final DashboardService service;
    @GetMapping
    public ApiResponse<Map<String, Object>> get(@Valid @ModelAttribute DashboardQuery query) {
        return ApiResponse.success(service.report(query));
    }
}
