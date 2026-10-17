package com.huit.zella.product;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/admin/home/featured-products") @RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','MARKETING')")
public class FeaturedProductSettingsController {
    private final FeaturedProductSettingsService service;
    @GetMapping public ApiResponse<FeaturedProductSettingsService.Settings> get(){return ApiResponse.success(service.get());}
    @PutMapping public ApiResponse<FeaturedProductSettingsService.Settings> save(@Valid @RequestBody FeaturedProductSettingsService.Request r){return ApiResponse.success(service.save(r));}
}
