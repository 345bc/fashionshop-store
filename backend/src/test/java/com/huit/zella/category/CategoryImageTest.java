package com.huit.zella.category;

import com.huit.zella.product.ProductRepository;
import com.huit.zella.productimage.ProductImageFileStorage;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CategoryImageTest {
    @Test
    void replacingStoredImageDeletesOldFileOnlyAfterCommit() {
        CategoryRepository repository = mock(CategoryRepository.class);
        ProductImageFileStorage storage = mock(ProductImageFileStorage.class);
        CategoryService service = new CategoryService(repository, mock(ProductRepository.class), storage);
        Category category = new Category(); category.setId(1L);
        String name = "12345678-1234-1234-1234-123456789abc.png";
        category.setImageUrl("https://images.example/category-images/" + name);
        when(storage.categoryPublicUrlPrefix()).thenReturn("https://images.example/category-images/");
        when(repository.findByIdForImageUpdate(1L)).thenReturn(Optional.of(category));
        when(repository.save(category)).thenReturn(category);
        TransactionSynchronizationManager.initSynchronization();
        try {
            CategoryResponse response = service.replaceImage(1L, "https://images.example/category-images/new.png");
            assertEquals("https://images.example/category-images/new.png", response.imageUrl());
            verify(storage, never()).deleteCategory(anyString());
            TransactionSynchronizationManager.getSynchronizations().forEach(sync -> sync.afterCommit());
            verify(storage).deleteCategory(name);
        } finally { TransactionSynchronizationManager.clearSynchronization(); }
    }

    @Test
    void uploadFailureCleansNewObjectAndPreservesError() {
        CategoryService service = mock(CategoryService.class);
        ProductImageFileStorage storage = mock(ProductImageFileStorage.class);
        MockMultipartFile file = new MockMultipartFile("file", "test.png", "image/png", new byte[]{1});
        when(storage.storeCategory(file)).thenReturn(new ProductImageFileStorage.StoredImage("new.png", "https://images/new.png"));
        RuntimeException failure = new IllegalStateException("database failure");
        when(service.replaceImage(1L, "https://images/new.png")).thenThrow(failure);
        assertSame(failure, assertThrows(RuntimeException.class, () -> new CategoryImageUploadService(service, storage).upload(1L, file)));
        verify(storage).deleteCategory("new.png");
    }

    @Test
    void createAndResponsesCarryImageUrl() {
        CategoryRepository repository = mock(CategoryRepository.class);
        CategoryService service = new CategoryService(repository, mock(ProductRepository.class), mock(ProductImageFileStorage.class));
        when(repository.save(any(Category.class))).thenAnswer(invocation -> invocation.getArgument(0));
        CategoryResponse response = service.create(new CreateCategoryRequest("Nữ", null, true, "https://images/category.png"));
        assertEquals("https://images/category.png", response.imageUrl());
        Category category = new Category(); category.setImageUrl(response.imageUrl());
        assertEquals(response.imageUrl(), CategorySummaryResponse.from(category).imageUrl());
    }
}
