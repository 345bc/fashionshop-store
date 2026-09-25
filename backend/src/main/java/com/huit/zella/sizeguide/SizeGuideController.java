package com.huit.zella.sizeguide;

import com.huit.zella.category.CategoryResponse;
import com.huit.zella.category.CategoryService;
import com.huit.zella.common.api.ApiResponse;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/sizeguide")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SizeGuideController {
    SizeGuideService sizeGuideService;

    @GetMapping
    public ApiResponse<List<SizeGuideResponse>> getAllUnits() {
        return ApiResponse.success(sizeGuideService.get());
    }
}
