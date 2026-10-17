package com.huit.zella.post;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.productimage.ProductImageFileStorage;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/v1/admin/posts/images")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','MARKETING')")
public class PostImageController {
    private final ProductImageFileStorage storage;

    @PostMapping(consumes = "multipart/form-data")
    public ApiResponse<ImageResponse> upload(@RequestParam(value = "file", required = false) MultipartFile file) {
        if (file == null) {
            throw new com.huit.zella.common.exception.BusinessException(
                    org.springframework.http.HttpStatus.BAD_REQUEST, "IMAGE_REQUIRED", "Vui lòng chọn ảnh bìa");
        }
        var image = storage.storePost(file);
        return ApiResponse.success(new ImageResponse(image.url()));
    }

    public record ImageResponse(String url) {}
}
