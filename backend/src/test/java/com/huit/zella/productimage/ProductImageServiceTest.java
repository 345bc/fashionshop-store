package com.huit.zella.productimage;

import com.huit.zella.product.Product;
import com.huit.zella.product.ProductRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.mockito.Mockito.*;

class ProductImageServiceTest {
    private final ProductImageRepository images = mock(ProductImageRepository.class);
    private final ProductRepository products = mock(ProductRepository.class);
    private final ProductImageFileStorage storage = mock(ProductImageFileStorage.class);
    private final ProductImageService service = new ProductImageService(images, products, storage);

    @Test
    void makingImagePrimaryClearsPreviousPrimary() {
        Product product = new Product();
        product.setId(3L);
        ProductImage previous = new ProductImage();
        previous.setId(1L);
        previous.setPrimary(true);
        when(products.findByIdForImageUpdate(3L)).thenReturn(Optional.of(product));
        when(images.findByProductIdAndIsPrimaryTrue(3L)).thenReturn(Optional.of(previous));
        when(images.save(any(ProductImage.class))).thenAnswer(call -> call.getArgument(0));

        service.create(new CreateProductImageRequest(3L, " https://example.com/shirt.jpg ", true, 0));

        assertFalse(previous.isPrimary());
        verify(images).save(argThat(image -> image.isPrimary()
                && image.getImageUrl().equals("https://example.com/shirt.jpg")));
    }

    @Test
    void deletingImageAlsoDeletesItsR2File() {
        String fileName = "73b6237e-933d-412f-9801-b963da70c9e2.png";
        ProductImage image = new ProductImage();
        image.setId(7L);
        image.setImageUrl("https://images.example.com/product-images/" + fileName);
        when(images.findById(7L)).thenReturn(Optional.of(image));
        when(storage.publicUrlPrefix()).thenReturn("https://images.example.com/product-images/");

        service.delete(7L);

        verify(images).delete(image);
        verify(storage).delete(fileName);
    }
}
