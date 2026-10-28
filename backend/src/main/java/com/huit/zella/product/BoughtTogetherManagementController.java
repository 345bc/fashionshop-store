package com.huit.zella.product;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController @RequiredArgsConstructor
@RequestMapping("/api/v1/admin/bought-together")
@PreAuthorize("hasAnyRole('ADMIN','MARKETING')")
public class BoughtTogetherManagementController {
    private final BoughtTogetherSettingsService settings;
    private final BoughtTogetherService service;

    @GetMapping("/settings")
    public ApiResponse<BoughtTogetherSettingsService.Settings> settings() {
        return ApiResponse.success(settings.get());
    }
    @PutMapping("/settings")
    public ApiResponse<BoughtTogetherSettingsService.Settings> save(@Valid @RequestBody BoughtTogetherSettingsService.Settings request) {
        return ApiResponse.success(settings.save(request));
    }
    @GetMapping("/status")
    public ApiResponse<BoughtTogetherService.Status> status() {
        return ApiResponse.success(service.status(false));
    }
    @GetMapping("/itemsets")
    public ApiResponse<BoughtTogetherService.MiningPage<BoughtTogetherService.FrequentItemset>> itemsets(
            @RequestParam(defaultValue="0") int page, @RequestParam(defaultValue="20") int size,
            @RequestParam(defaultValue="0") int level) {
        return ApiResponse.success(service.itemsets(page,size,level));
    }
    @GetMapping("/rules")
    public ApiResponse<BoughtTogetherService.MiningPage<FpGrowth.Rule>> rules(
            @RequestParam(defaultValue="0") int page, @RequestParam(defaultValue="20") int size) {
        return ApiResponse.success(service.associationRules(page,size));
    }
    @GetMapping("/preview")
    public ApiResponse<BoughtTogetherService.Preview> preview(@RequestParam java.util.List<Long> productIds) {
        return ApiResponse.success(service.preview(productIds));
    }
    @PostMapping("/rebuild")
    public ApiResponse<BoughtTogetherService.Status> rebuild() {
        return ApiResponse.success(service.status(true));
    }
    @GetMapping("/preview/{productId}")
    public ApiResponse<BoughtTogetherService.Preview> preview(@PathVariable long productId) {
        return ApiResponse.success(service.preview(productId));
    }
}
