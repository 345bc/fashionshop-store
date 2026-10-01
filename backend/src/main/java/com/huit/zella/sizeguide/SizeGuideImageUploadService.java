package com.huit.zella.sizeguide;

import com.huit.zella.productimage.ProductImageFileStorage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class SizeGuideImageUploadService {
    private final SizeGuideService sizeGuideService;
    private final ProductImageFileStorage storage;

    public SizeGuideResponse upload(Long id, MultipartFile file) {
        // Validate the guide before writing a file to R2.
        sizeGuideService.get(id);
        ProductImageFileStorage.StoredImage stored = storage.storeSizeGuide(file);
        try {
            return sizeGuideService.replaceImage(id, stored.url());
        } catch (RuntimeException error) {
            try {
                storage.deleteSizeGuide(stored.fileName());
            } catch (RuntimeException ignored) {
                // Preserve the database error returned to the caller.
            }
            throw error;
        }
    }
}
