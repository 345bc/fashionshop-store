package com.huit.zella.productvariant;

import com.huit.zella.color.Color;
import com.huit.zella.color.ColorRepository;
import com.huit.zella.product.Product;
import com.huit.zella.product.ProductRepository;
import com.huit.zella.size.Size;
import com.huit.zella.size.SizeRepository;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.*;

class ProductVariantServiceTest {
    private final ProductVariantRepository variants = mock(ProductVariantRepository.class);
    private final ProductRepository products = mock(ProductRepository.class);
    private final SizeRepository sizes = mock(SizeRepository.class);
    private final ColorRepository colors = mock(ColorRepository.class);
    private final ProductVariantService service = new ProductVariantService(variants, products, sizes, colors);

    @Test
    void generatesSkuFromProductSlugColorCodeAndSizeName() {
        Product product = new Product();
        product.setId(1L);
        product.setName("Áo thun");
        product.setSlug("ao-thun");
        Color color = new Color();
        color.setId(2);
        color.setName("Đen");
        color.setCode("DEN");
        Size size = new Size();
        size.setId(3);
        size.setName("XL");
        when(products.findById(1L)).thenReturn(Optional.of(product));
        when(colors.findById(2)).thenReturn(Optional.of(color));
        when(sizes.findById(3)).thenReturn(Optional.of(size));
        when(variants.save(any(ProductVariant.class))).thenAnswer(call -> call.getArgument(0));

        ProductVariantResponse result = service.create(new CreateProductVariantRequest(
                1L, 3, 2, BigDecimal.TEN, BigDecimal.ONE, 5, 0, true));

        assertEquals("ao-thun-DEN-XL", result.sku());
        verify(variants).existsBySkuIgnoreCase("ao-thun-DEN-XL");
    }
}
