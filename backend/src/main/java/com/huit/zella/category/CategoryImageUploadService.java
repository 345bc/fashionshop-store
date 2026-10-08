package com.huit.zella.category;

import com.huit.zella.productimage.ProductImageFileStorage;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class CategoryImageUploadService {
    private final CategoryService categoryService;
    private final ProductImageFileStorage storage;

    public CategoryResponse upload(Long id, MultipartFile file) {
        categoryService.get(id);
        ProductImageFileStorage.StoredImage image = storage.storeCategory(file);
        try {
            return categoryService.replaceImage(id, image.url());
        } catch (RuntimeException error) {
            try { storage.deleteCategory(image.fileName()); }
            catch (RuntimeException ignored) { /* Keep the database error. */ }
            throw error;
        }
    }
}
