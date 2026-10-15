package com.huit.zella.variantimage;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productimage.ProductImageFileStorage;
import com.huit.zella.productvariant.ProductVariantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class VariantImageUploadService {
    private final VariantImageService imageService;
    private final ProductImageFileStorage storage;
    private final ProductVariantRepository variantRepository;

    public VariantImageResponse upload(Long variantId, MultipartFile file, boolean isPrimary, int displayOrder) {
        if (displayOrder < 0) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_DISPLAY_ORDER", "Thứ tự ảnh không hợp lệ");
        }
        if (!variantRepository.existsById(variantId)) {
            throw new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_VARIANT_NOT_FOUND", "Product variant not found");
        }
        ProductImageFileStorage.StoredImage stored = storage.storeVariant(file);
        try {
            return imageService.create(new CreateVariantImageRequest(variantId, stored.url(), isPrimary, displayOrder));
        } catch (RuntimeException error) {
            try {
                storage.deleteVariant(stored.fileName());
            } catch (RuntimeException ignored) {
                // Preserve the database error returned to the caller.
            }
            throw error;
        }
    }
}
