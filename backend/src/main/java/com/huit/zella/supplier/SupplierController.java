package com.huit.zella.supplier;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.sizeguide.SizeGuideResponse;
import com.huit.zella.sizeguide.SizeGuideService;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/supplier")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SupplierController {
    SupplierService supplierService;

    @GetMapping
    public ApiResponse<List<SupplierRespone>> getAllUnits() {
        return ApiResponse.success(supplierService.get());
    }
}
