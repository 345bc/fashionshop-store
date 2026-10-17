package com.huit.zella.promotion;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/admin/home/new-products") @RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','MARKETING')")
public class HomeAppearanceController {
    private final HomeAppearanceService service;
    @GetMapping public ApiResponse<HomeAppearanceService.Settings> get() { return ApiResponse.success(service.get()); }
    @PutMapping public ApiResponse<HomeAppearanceService.Settings> save(@Valid @RequestBody HomeAppearanceService.Request request) {
        return ApiResponse.success(service.save(request));
    }
}
