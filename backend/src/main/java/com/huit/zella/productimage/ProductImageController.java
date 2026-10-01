package com.huit.zella.productimage;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/v1/product-image")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ProductImageController {
    ProductImageService imageService;
    ProductImageUploadService uploadService;

    @GetMapping
    public ApiResponse<List<ProductImageResponse>> list(@RequestParam Long productId) {
        return ApiResponse.success(imageService.list(productId));
    }

    @GetMapping("/{id}")
    public ApiResponse<ProductImageResponse> get(@PathVariable Long id) {
        return ApiResponse.success(imageService.get(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping
    public ResponseEntity<ApiResponse<ProductImageResponse>> create(@Valid @RequestBody CreateProductImageRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(imageService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping(value = "/upload", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<ProductImageResponse>> upload(
            @RequestParam("productId") Long productId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("isPrimary") boolean isPrimary,
            @RequestParam("displayOrder") int displayOrder
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(uploadService.upload(productId, file, isPrimary, displayOrder)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<ProductImageResponse> update(@PathVariable Long id, @Valid @RequestBody CreateProductImageRequest request) {
        return ApiResponse.success(imageService.update(id, request));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        imageService.delete(id);
        return ApiResponse.success(null);
    }
}
