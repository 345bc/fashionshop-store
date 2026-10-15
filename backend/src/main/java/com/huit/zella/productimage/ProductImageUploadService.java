package com.huit.zella.productimage;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.ProductRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class ProductImageUploadService {
    private final ProductImageService imageService;
    private final ProductImageFileStorage storage;
    private final ProductRepository productRepository;

    public ProductImageResponse upload(Long productId, MultipartFile file, boolean isPrimary, int displayOrder) {
        if (displayOrder < 0) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_DISPLAY_ORDER", "Thứ tự ảnh không hợp lệ");
        }
        if (!productRepository.existsById(productId)) {
            throw new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found");
        }
        ProductImageFileStorage.StoredImage stored = storage.store(file);
        try {
            return imageService.create(new CreateProductImageRequest(productId, stored.url(), isPrimary, displayOrder));
        } catch (RuntimeException error) {
            try {
                storage.delete(stored.fileName());
            } catch (RuntimeException ignored) {
                // Keep the database error as the cause returned to the caller.
            }
            throw error;
        }
    }

}
