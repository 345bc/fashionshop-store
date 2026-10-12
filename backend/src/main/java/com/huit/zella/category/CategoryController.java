package com.huit.zella.category;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.common.api.PageResponse;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/category")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CategoryController {
    CategoryService categoryService;
    CategoryImageUploadService categoryImageUploadService;

    @GetMapping("/parents")
    public ApiResponse<List<CategoryResponse>> listParents() {
        return ApiResponse.success(categoryService.listParents());
    }

    @GetMapping
    public ApiResponse<PageResponse<CategoryResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Boolean active,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(categoryService.list(
                q,
                active,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }

    @GetMapping("/parents/{parentId}")
    public ApiResponse<List<CategoryResponse>> listByParent(@PathVariable Long parentId) {
        return ApiResponse.success(categoryService.listByParent(parentId));
    }

    @GetMapping("/{id}")
    public ApiResponse<CategoryResponse> get(@PathVariable Long id) {
        return ApiResponse.success(categoryService.get(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping
    public ResponseEntity<ApiResponse<CategoryResponse>> create(@Valid @RequestBody CreateCategoryRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(categoryService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<CategoryResponse> update(@PathVariable Long id, @Valid @RequestBody CreateCategoryRequest request) {
        return ApiResponse.success(categoryService.update(id, request));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        categoryService.delete(id);
        return ApiResponse.success(null);
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping(value = "/{id}/image", consumes = "multipart/form-data")
    public ApiResponse<CategoryResponse> uploadImage(@PathVariable Long id, @RequestParam("file") MultipartFile file) {
        return ApiResponse.success(categoryImageUploadService.upload(id, file));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @DeleteMapping("/{id}/image")
    public ApiResponse<CategoryResponse> removeImage(@PathVariable Long id) {
        return ApiResponse.success(categoryService.replaceImage(id, null));
    }
}
