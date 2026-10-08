package com.huit.zella.product;

import com.huit.zella.category.CategoryRepository;
import com.huit.zella.color.Color;
import com.huit.zella.productimage.ProductImage;
import com.huit.zella.productimage.ProductImageRepository;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.productvariant.ProductVariantRepository;
import com.huit.zella.sizeguide.SizeGuideRepository;
import com.huit.zella.supplier.SupplierRepository;
import com.huit.zella.variantimage.VariantImage;
import com.huit.zella.variantimage.VariantImageRepository;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class ProductCardServiceTest {
    private final ProductRepository products = mock(ProductRepository.class);
    private final ProductImageRepository images = mock(ProductImageRepository.class);
    private final ProductVariantRepository variants = mock(ProductVariantRepository.class);
    private final VariantImageRepository variantImages = mock(VariantImageRepository.class);
    private final ProductService service = new ProductService(products, mock(CategoryRepository.class),
            mock(SupplierRepository.class), mock(SizeGuideRepository.class), images, variants, variantImages);

    @Test
    void sharesColorImageAcrossSizesWithoutMixingProducts() {
        Product first = product(1L);
        Product second = product(2L);
        Color color = new Color();
        color.setId(3);
        color.setName("White");
        color.setHexCode("#FFFFFF");
        ProductVariant small = variant(10L, first, color);
        ProductVariant medium = variant(11L, first, color);
        ProductVariant otherProduct = variant(12L, second, color);
        PageRequest pageable = PageRequest.of(0, 12);
        when(products.searchCards("", null, false, List.of(-1), false, List.of(-1), null, null, pageable))
                .thenReturn(new PageImpl<>(List.of(first, second), pageable, 2));

        ProductImage productImage = new ProductImage();
        productImage.setProduct(first);
        productImage.setImageUrl("product.jpg");
        when(images.findByProductIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(List.of(1L, 2L)))
                .thenReturn(List.of(productImage));
        when(variants.findCardVariants(List.of(1L, 2L)))
                .thenReturn(List.of(small, medium, otherProduct));
        when(variantImages.findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(List.of(10L, 11L, 12L)))
                .thenReturn(List.of(image(medium, "white-primary.jpg"), image(medium, "white-other.jpg")));

        Page<ProductCardResponse> result = service.listCards(null, null, null, null, null, null, pageable);

        ProductCardResponse firstCard = result.getContent().getFirst();
        assertEquals("product.jpg", firstCard.imageUrl());
        assertEquals(1, firstCard.colors().size());
        assertEquals("white-primary.jpg", firstCard.colors().getFirst().imageUrl());
        assertNull(result.getContent().get(1).colors().getFirst().imageUrl());
        assertEquals(2, result.getTotalElements());
        verify(variantImages, times(1))
                .findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(List.of(10L, 11L, 12L));
    }

    @Test
    void emptyPageSkipsImageAndVariantQueriesAndKeepsTotal() {
        PageRequest pageable = PageRequest.of(3, 12);
        when(products.searchCards("shirt", null, false, List.of(-1), false, List.of(-1), null, null, pageable))
                .thenReturn(new PageImpl<>(List.of(), pageable, 24));

        Page<ProductCardResponse> result = service.listCards(" shirt ", null, null, null, null, null, pageable);

        assertTrue(result.isEmpty());
        assertEquals(24, result.getTotalElements());
        assertEquals(3, result.getNumber());
        verifyNoInteractions(images, variants, variantImages);
    }

    private Product product(Long id) {
        Product product = new Product();
        product.setId(id);
        return product;
    }

    private ProductVariant variant(Long id, Product product, Color color) {
        ProductVariant variant = new ProductVariant();
        variant.setId(id);
        variant.setProduct(product);
        variant.setColor(color);
        return variant;
    }

    private VariantImage image(ProductVariant variant, String url) {
        VariantImage image = new VariantImage();
        image.setVariant(variant);
        image.setImageUrl(url);
        return image;
    }
}
