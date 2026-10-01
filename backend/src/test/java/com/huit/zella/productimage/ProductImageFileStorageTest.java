package com.huit.zella.productimage;

import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class ProductImageFileStorageTest {
    private final S3Client s3Client = mock(S3Client.class);
    private final ProductImageFileStorage storage =
            new ProductImageFileStorage(s3Client, "photos", 1024, "https://images.example.com/");

    @Test
    void storesImageInR2AndReturnsPublicUrl() {
        byte[] png = {(byte) 0x89, 'P', 'N', 'G', 13, 10, 0x1a, 10, 0, 0, 0, 0};
        var stored = storage.store(new MockMultipartFile("file", "photo.png", "image/png", png));

        assertEquals("https://images.example.com/product-images/" + stored.fileName(), stored.url());
        verify(s3Client).putObject(argThat((PutObjectRequest request) ->
                request.bucket().equals("photos")
                        && request.key().equals("product-images/" + stored.fileName())
                        && request.contentType().equals("image/png")), any(RequestBody.class));
    }

    @Test
    void storesVariantImageInItsOwnFolder() {
        byte[] png = {(byte) 0x89, 'P', 'N', 'G', 13, 10, 0x1a, 10, 0, 0, 0, 0};
        var stored = storage.storeVariant(new MockMultipartFile("file", "variant.png", "image/png", png));

        assertEquals("https://images.example.com/variant-images/" + stored.fileName(), stored.url());
        verify(s3Client).putObject(argThat((PutObjectRequest request) ->
                request.bucket().equals("photos")
                        && request.key().equals("variant-images/" + stored.fileName())
                        && request.contentType().equals("image/png")), any(RequestBody.class));
    }

    @Test
    void storesSizeGuideImageInItsOwnFolder() {
        byte[] png = {(byte) 0x89, 'P', 'N', 'G', 13, 10, 0x1a, 10, 0, 0, 0, 0};
        var stored = storage.storeSizeGuide(new MockMultipartFile("file", "guide.png", "image/png", png));

        assertEquals("https://images.example.com/size-guide-images/" + stored.fileName(), stored.url());
        verify(s3Client).putObject(argThat((PutObjectRequest request) ->
                request.bucket().equals("photos")
                        && request.key().equals("size-guide-images/" + stored.fileName())
                        && request.contentType().equals("image/png")), any(RequestBody.class));
    }

    @Test
    void rejectsInvalidImageBeforeUpload() {
        assertThrows(BusinessException.class,
                () -> storage.store(new MockMultipartFile("file", "photo.png", "image/png", "not an image".getBytes())));
        verifyNoInteractions(s3Client);
    }
}
