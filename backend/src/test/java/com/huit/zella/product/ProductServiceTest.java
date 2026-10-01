package com.huit.zella.product;

import com.huit.zella.category.Category;
import com.huit.zella.category.CategoryRepository;
import com.huit.zella.sizeguide.SizeGuide;
import com.huit.zella.sizeguide.SizeGuideRepository;
import com.huit.zella.supplier.Supplier;
import com.huit.zella.supplier.SupplierRepository;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.*;

class ProductServiceTest {
    private final ProductRepository products = mock(ProductRepository.class);
    private final CategoryRepository categories = mock(CategoryRepository.class);
    private final SupplierRepository suppliers = mock(SupplierRepository.class);
    private final SizeGuideRepository guides = mock(SizeGuideRepository.class);
    private final ProductService service = new ProductService(products, categories, suppliers, guides);

    @Test
    void createAcceptsOptionalTextAndDefaultsToActive() {
        when(categories.findByIdAndIsActiveTrue(1L)).thenReturn(Optional.of(new Category()));
        when(suppliers.findByIdAndIsActiveTrue(2L)).thenReturn(Optional.of(new Supplier()));
        when(guides.findByIdAndIsActiveTrue(3L)).thenReturn(Optional.of(new SizeGuide()));
        when(products.save(any(Product.class))).thenAnswer(call -> call.getArgument(0));

        ProductResponse result = service.create(new CreateProductRequest(
                " Áo thun Đen ", null, null, null, BigDecimal.TEN, 1L, 2L, 3L, null));

        assertEquals("ao-thun-den", result.slug());
        assertTrue(result.isActive());
        verify(products).save(argThat(product -> product.getDescription() == null
                && product.getStyle() == null && product.getOccasion() == null));
    }
}
