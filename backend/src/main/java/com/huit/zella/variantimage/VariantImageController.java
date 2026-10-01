package com.huit.zella.variantimage;

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
@RequestMapping("/api/v1/variant-image")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class VariantImageController {
    VariantImageService imageService;
    VariantImageUploadService uploadService;

    @GetMapping
    public ApiResponse<List<VariantImageResponse>> list(@RequestParam Long variantId) {
        return ApiResponse.success(imageService.list(variantId));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping(value = "/upload", consumes = "multipart/form-data")
    public ResponseEntity<ApiResponse<VariantImageResponse>> upload(
            @RequestParam("variantId") Long variantId,
            @RequestParam("file") MultipartFile file,
            @RequestParam("isPrimary") boolean isPrimary,
            @RequestParam("displayOrder") int displayOrder
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(uploadService.upload(variantId, file, isPrimary, displayOrder)));
    }

    @GetMapping("/{id}")
    public ApiResponse<VariantImageResponse> get(@PathVariable Long id) {
        return ApiResponse.success(imageService.get(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping
    public ResponseEntity<ApiResponse<VariantImageResponse>> create(@Valid @RequestBody CreateVariantImageRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(imageService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<VariantImageResponse> update(@PathVariable Long id, @Valid @RequestBody CreateVariantImageRequest request) {
        return ApiResponse.success(imageService.update(id, request));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        imageService.delete(id);
        return ApiResponse.success(null);
    }
}
