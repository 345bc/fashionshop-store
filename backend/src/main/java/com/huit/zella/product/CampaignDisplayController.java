package com.huit.zella.product;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.promotion.NewProductSpotlightService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/v1/product/campaign-displays") @RequiredArgsConstructor
public class CampaignDisplayController {
    private final NewProductSpotlightService service;
    @GetMapping public ApiResponse<List<NewProductSpotlightService.Spotlight>> list() {
        return ApiResponse.success(service.list());
    }
}
