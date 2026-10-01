package com.huit.zella.sizeguide;

import com.huit.zella.productimage.ProductImageFileStorage;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class SizeGuideImageUploadServiceTest {
    private final SizeGuideService guides = mock(SizeGuideService.class);
    private final ProductImageFileStorage storage = mock(ProductImageFileStorage.class);
    private final SizeGuideImageUploadService service = new SizeGuideImageUploadService(guides, storage);

    @Test
    void uploadsImageAndLinksItToGuide() {
        var file = new MockMultipartFile("file", "guide.png", "image/png", new byte[] {1});
        var stored = new ProductImageFileStorage.StoredImage("image.png", "https://images.example.com/size-guide-images/image.png");
        when(storage.storeSizeGuide(file)).thenReturn(stored);

        service.upload(7L, file);

        verify(guides).get(7L);
        verify(guides).replaceImage(7L, stored.url());
    }

    @Test
    void removesNewFileWhenDatabaseUpdateFails() {
        var file = new MockMultipartFile("file", "guide.png", "image/png", new byte[] {1});
        var stored = new ProductImageFileStorage.StoredImage("image.png", "https://images.example.com/size-guide-images/image.png");
        when(storage.storeSizeGuide(file)).thenReturn(stored);
        when(guides.replaceImage(7L, stored.url())).thenThrow(new IllegalStateException("database failed"));

        assertThrows(IllegalStateException.class, () -> service.upload(7L, file));

        verify(storage).deleteSizeGuide(stored.fileName());
    }
}
