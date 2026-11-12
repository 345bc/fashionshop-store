package com.huit.zella.productvariant;

import com.huit.zella.color.Color;
import com.huit.zella.color.ColorRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.Product;
import com.huit.zella.product.ProductRepository;
import com.huit.zella.size.Size;
import com.huit.zella.size.SizeRepository;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
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
                1L, 3, 2, BigDecimal.TEN, BigDecimal.ONE, 0, 0, true));

        assertEquals("ao-thun-DEN-XL", result.sku());
        verify(variants).existsBySkuIgnoreCase("ao-thun-DEN-XL");
    }

    @Test
    void listsOrderHistoryForEachVariant() {
        var sold = new ProductVariant();
        sold.setId(1L);
        var unsold = new ProductVariant();
        unsold.setId(2L);
        var page = PageRequest.of(0, 15);
        when(variants.findByProductId(10L, page)).thenReturn(new PageImpl<>(List.of(sold, unsold)));
        when(variants.findVariantIdsWithOrders(List.of(1L, 2L))).thenReturn(List.of(1L));

        var rows = service.list(null, 10L, page).getContent();

        assertTrue(rows.get(0).hasOrders());
        assertFalse(rows.get(1).hasOrders());
    }

    @Test
    void deleteKeepsVariantsWithOrdersOrOtherReferences() {
        when(variants.deleteWithoutOrders(1L)).thenReturn(1);
        when(variants.findById(2L)).thenReturn(Optional.of(new ProductVariant()));
        when(variants.deleteWithoutOrders(3L)).thenThrow(new DataIntegrityViolationException("foreign key"));

        service.delete(1L);
        assertEquals("VARIANT_HAS_ORDERS", assertThrows(BusinessException.class, () -> service.delete(2L)).getCode());
        assertEquals("VARIANT_IN_USE", assertThrows(BusinessException.class, () -> service.delete(3L)).getCode());
        assertEquals("PRODUCT_VARIANT_NOT_FOUND", assertThrows(BusinessException.class, () -> service.delete(4L)).getCode());
    }
}
