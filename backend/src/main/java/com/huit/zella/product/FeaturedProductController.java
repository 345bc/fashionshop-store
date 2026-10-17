package com.huit.zella.product;

import com.huit.zella.common.api.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/product/featured") @RequiredArgsConstructor
public class FeaturedProductController {
    private final FeaturedProductService service;
    @GetMapping public ApiResponse<FeaturedProductService.Result> get(@RequestParam(defaultValue="8") int size) {
        return ApiResponse.success(service.get(size));
    }
}
