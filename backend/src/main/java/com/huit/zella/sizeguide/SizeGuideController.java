package com.huit.zella.sizeguide;

import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageRequest;

import com.huit.zella.common.api.PageResponse;

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

@RestController
@RequestMapping("/api/v1/sizeguide")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SizeGuideController {
    SizeGuideService sizeGuideService;
    SizeGuideImageUploadService imageUploadService;

    @GetMapping
    public ApiResponse<PageResponse<SizeGuideResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Boolean active,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(sizeGuideService.list(
                q, active,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }

    @GetMapping("/{id}")
    public ApiResponse<SizeGuideResponse> get(@PathVariable Long id) {
        return ApiResponse.success(sizeGuideService.get(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping
    public ResponseEntity<ApiResponse<SizeGuideResponse>> create(@Valid @RequestBody CreateSizeGuideRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(sizeGuideService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<SizeGuideResponse> update(@PathVariable Long id, @Valid @RequestBody CreateSizeGuideRequest request) {
        return ApiResponse.success(sizeGuideService.update(id, request));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping(value = "/{id}/image", consumes = "multipart/form-data")
    public ApiResponse<SizeGuideResponse> uploadImage(@PathVariable Long id, @RequestParam("file") MultipartFile file) {
        return ApiResponse.success(imageUploadService.upload(id, file));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @DeleteMapping("/{id}/image")
    public ApiResponse<SizeGuideResponse> removeImage(@PathVariable Long id) {
        return ApiResponse.success(sizeGuideService.removeImage(id));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        sizeGuideService.delete(id);
        return ApiResponse.success(null);
    }
}
