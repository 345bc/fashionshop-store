package com.huit.zella.product;

import com.huit.zella.category.Category;
import com.huit.zella.category.CategoryRepository;
import com.huit.zella.sizeguide.SizeGuide;
import com.huit.zella.sizeguide.SizeGuideRepository;
import com.huit.zella.supplier.Supplier;
import com.huit.zella.supplier.SupplierRepository;
import com.huit.zella.productimage.ProductImageRepository;
import com.huit.zella.productvariant.ProductVariantRepository;
import com.huit.zella.variantimage.VariantImageRepository;
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
    private final ProductService service = new ProductService(new com.huit.zella.promotion.PromotionPricingService(org.mockito.Mockito.mock(com.huit.zella.promotion.PromotionRepository.class), java.time.Clock.systemUTC()), products, categories, suppliers, guides,
            mock(ProductImageRepository.class), mock(ProductVariantRepository.class), mock(VariantImageRepository.class), mock(com.huit.zella.review.ProductReviewRepository.class));

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

    @Test
    void contentUpdatePreservesPriceAvailabilityAndCatalogAssignments() {
        Product product = new Product();
        product.setId(7L); product.setName("Áo cũ"); product.setSlug("ao-cu");
        product.setBasePrice(new BigDecimal("500000")); product.setActive(false);
        Category category = new Category(); category.setId(1L); product.setCategory(category);
        Supplier supplier = new Supplier(); supplier.setId(2L); product.setSupplier(supplier);
        SizeGuide guide = new SizeGuide(); guide.setId(3L); product.setSizeGuide(guide);
        when(products.findById(7L)).thenReturn(Optional.of(product));
        when(products.save(any(Product.class))).thenAnswer(call -> call.getArgument(0));
        ProductResponse result = service.updateContent(7L,
                new ProductContentRequest("Áo mới", "Mô tả mới", "Tối giản", "Đi làm"));
        assertEquals(new BigDecimal("500000"), result.basePrice());
        org.junit.jupiter.api.Assertions.assertFalse(result.isActive());
        assertEquals(1L, result.categoryId()); assertEquals(2L, result.supplierId()); assertEquals(3L, result.sizeGuideId());
        assertEquals("Áo mới", result.name());
    }
}
