package com.huit.zella.variantimage;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.productvariant.ProductVariantRepository;
import com.huit.zella.productimage.ProductImageFileStorage;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class VariantImageServiceTest {
    private final VariantImageRepository images = mock(VariantImageRepository.class);
    private final ProductVariantRepository variants = mock(ProductVariantRepository.class);
    private final ProductImageFileStorage storage = mock(ProductImageFileStorage.class);
    private final VariantImageService service = new VariantImageService(images, variants, storage);

    @Test
    void makingImagePrimaryClearsPreviousPrimaryForSameVariant() {
        ProductVariant variant = new ProductVariant();
        variant.setId(3L);
        VariantImage previous = new VariantImage();
        previous.setId(1L);
        previous.setPrimary(true);
        when(variants.findByIdForImageUpdate(3L)).thenReturn(Optional.of(variant));
        when(images.findByVariantIdAndIsPrimaryTrue(3L)).thenReturn(Optional.of(previous));
        when(images.save(any(VariantImage.class))).thenAnswer(call -> call.getArgument(0));

        VariantImageResponse response = service.create(
                new CreateVariantImageRequest(3L, " https://example.com/variant.jpg ", true, 0));

        assertFalse(previous.isPrimary());
        assertEquals(3L, response.variantId());
        assertEquals("https://example.com/variant.jpg", response.imageUrl());
    }

    @Test
    void rejectsMissingVariant() {
        BusinessException error = assertThrows(BusinessException.class, () -> service.create(
                new CreateVariantImageRequest(99L, "https://example.com/variant.jpg", false, 0)));

        assertEquals(HttpStatus.NOT_FOUND, error.getStatus());
        assertEquals("PRODUCT_VARIANT_NOT_FOUND", error.getCode());
        verify(images, never()).save(any());
    }
}
