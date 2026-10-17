package com.huit.zella.product;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.promotion.NewProductSpotlightService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/product/new-arrivals/spotlight") @RequiredArgsConstructor
public class NewProductSpotlightController {
    private final NewProductSpotlightService service;
    @GetMapping public ApiResponse<NewProductSpotlightService.Spotlight> get() {
        return ApiResponse.success(service.get());
    }
}
