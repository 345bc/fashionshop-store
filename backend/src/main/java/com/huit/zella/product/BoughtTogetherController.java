package com.huit.zella.product;

import com.huit.zella.common.api.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController @RequiredArgsConstructor
@RequestMapping("/api/v1/product")
public class BoughtTogetherController {
    private final BoughtTogetherService service;
    @GetMapping("/bought-together")
    public ApiResponse<BoughtTogetherService.Result> get(@RequestParam java.util.List<Long> productIds,
            @RequestParam(defaultValue="24") int size) {
        return ApiResponse.success(service.get(productIds,size));
    }
    @GetMapping("/{id}/bought-together")
    public ApiResponse<BoughtTogetherService.Result> get(@PathVariable long id,@RequestParam(defaultValue="8") int size) {
        return ApiResponse.success(service.get(id,size));
    }
}
