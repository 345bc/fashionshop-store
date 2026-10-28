package com.huit.zella.chat;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/chat")
public class ImageRecognitionController {
    private final ImageRecognitionService service;
    private final RecognitionCatalogService catalog;
    public ImageRecognitionController(ImageRecognitionService service, RecognitionCatalogService catalog) {
        this.service = service;
        this.catalog = catalog;
    }
    public record RecognitionResponse(int width, int height,
            java.util.List<ImageRecognitionService.Detection> detections,
            java.util.List<RecognitionCatalogService.Suggestion> suggestions) {}

    public record ImageRequest(@NotBlank @Size(max = 7_000_000) String image) {}

    @PostMapping("/image-recognition")
    public ResponseEntity<ApiResponse<RecognitionResponse>> predict(@Valid @RequestBody ImageRequest request) {
        var result = service.predict(request.image());
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(ApiResponse.success(
                new RecognitionResponse(result.width(), result.height(), result.detections(), catalog.suggest(result.detections()))));
    }
}
