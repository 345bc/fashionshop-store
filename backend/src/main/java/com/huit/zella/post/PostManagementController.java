package com.huit.zella.post;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/posts")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','MARKETING')")
public class PostManagementController {
    private final PostService service;

    @GetMapping
    public ApiResponse<PageResponse<PostResponse>> list(@RequestParam(required = false) String q, @RequestParam(required = false) Long categoryId, @RequestParam(required = false) PostStatus status, @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.success(PageResponse.from(service.list(true, q, categoryId, status, page, size)));
    }

    @GetMapping("/{id}")
    public ApiResponse<PostResponse> get(@PathVariable Long id) {
        return ApiResponse.success(service.get(id));
    }

    @PostMapping
    public ApiResponse<PostResponse> create(@Valid @RequestBody PostRequest r, @AuthenticationPrincipal CurrentUser user) {
        return ApiResponse.success(service.save(null, r, user.id()));
    }

    @PutMapping("/{id}")
    public ApiResponse<PostResponse> update(@PathVariable Long id, @Valid @RequestBody PostRequest r, @AuthenticationPrincipal CurrentUser user) {
        return ApiResponse.success(service.save(id, r, user.id()));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ApiResponse.success(null);
    }

    @GetMapping("/categories")
    public ApiResponse<List<PostCategory>> categories() {
        return ApiResponse.success(service.categories(true));
    }

    @PostMapping("/categories")
    public ApiResponse<PostCategory> createCategory(@Valid @RequestBody PostCategoryRequest r) {
        return ApiResponse.success(service.saveCategory(null, r));
    }

    @PutMapping("/categories/{id}")
    public ApiResponse<PostCategory> updateCategory(@PathVariable Long id, @Valid @RequestBody PostCategoryRequest r) {
        return ApiResponse.success(service.saveCategory(id, r));
    }
}
