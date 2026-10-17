package com.huit.zella.promotion;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productimage.ProductImageFileStorage;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController @RequestMapping("/api/v1/campaigns/images") @RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','MARKETING')")
public class CampaignImageController {
    private final ProductImageFileStorage storage;
    public record ImageResponse(String url) {}
    @PostMapping(consumes="multipart/form-data")
    public ApiResponse<ImageResponse> upload(@RequestParam(value="file",required=false) MultipartFile file) {
        if(file==null) throw new BusinessException(HttpStatus.BAD_REQUEST,"IMAGE_REQUIRED","Vui lòng chọn ảnh chương trình");
        return ApiResponse.success(new ImageResponse(storage.storeCampaign(file).url()));
    }
}
