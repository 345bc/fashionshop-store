package com.huit.zella.post;

import com.huit.zella.common.api.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/posts")
@RequiredArgsConstructor
public class PostController {
    private final PostService service;

    @GetMapping
    public ApiResponse<PageResponse<PostResponse>> list(@RequestParam(required = false) String q, @RequestParam(required = false) Long categoryId, @RequestParam(defaultValue = "0") int page, @RequestParam(defaultValue = "12") int size) {
        return ApiResponse.success(PageResponse.from(service.list(false, q, categoryId, null, page, size)));
    }

    @GetMapping("/categories")
    public ApiResponse<List<PostCategory>> categories() {
        return ApiResponse.success(service.categories(false));
    }

    @GetMapping("/recommendations")
    public ApiResponse<List<PostResponse>> recommendations(@RequestParam(required = false) Long categoryId) {
        return ApiResponse.success(service.recommendations(categoryId));
    }

    @GetMapping("/{slug}")
    public ApiResponse<PostResponse> read(@PathVariable String slug) {
        return ApiResponse.success(service.read(slug));
    }
}
