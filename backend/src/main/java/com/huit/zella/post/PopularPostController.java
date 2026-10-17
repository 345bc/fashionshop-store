package com.huit.zella.post;

import com.huit.zella.common.api.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/posts/popular")
@RequiredArgsConstructor
public class PopularPostController {
    private final PopularPostService service;
    @GetMapping
    public ApiResponse<List<PopularPostService.PopularPost>> mostViewed(@RequestParam(defaultValue="1") int size) {
        int limit=Math.clamp(size,1,5);
        return ApiResponse.success(limit==1 ? service.mostViewed() : service.mostViewed(limit));
    }
}
