package com.huit.zella.category;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.ProductRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;
import java.util.List;
import org.springframework.data.domain.Sort;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class CategoryServiceTest {
    private final CategoryRepository categories = mock(CategoryRepository.class);
    private final ProductRepository products = mock(ProductRepository.class);
    private final CategoryService service = new CategoryService(categories, products,
            mock(com.huit.zella.productimage.ProductImageFileStorage.class));

    @Test
    void rejectsParentCycle() {
        Category category = new Category();
        category.setId(1L);
        Category child = new Category();
        child.setId(2L);
        child.setParent(category);
        when(categories.findByIdForImageUpdate(1L)).thenReturn(Optional.of(category));
        when(categories.findByIdAndIsActiveTrue(2L)).thenReturn(Optional.of(child));

        BusinessException error = assertThrows(BusinessException.class,
                () -> service.update(1L, new CreateCategoryRequest("Tops", 2L, true)));

        assertEquals("CATEGORY_CYCLE", error.getCode());
        verify(categories, never()).save(any());
    }

    @Test
    void cannotDeleteCategoryWithProducts() {
        Category category = new Category();
        category.setId(1L);
        when(categories.findByIdForImageUpdate(1L)).thenReturn(Optional.of(category));
        when(products.existsByCategoryId(1L)).thenReturn(true);

        BusinessException error = assertThrows(BusinessException.class, () -> service.delete(1L));

        assertEquals("CATEGORY_IN_USE", error.getCode());
        verify(categories, never()).delete(any());
    }

    @Test
    void listsOnlyRootCategoriesAsParentOptions() {
        Category parent = new Category();
        parent.setId(1L);
        parent.setName("Clothes");
        parent.setSlug("clothes");
        parent.setIsActive(true);
        when(categories.findByParentIsNull(any(Sort.class))).thenReturn(List.of(parent));

        List<CategoryResponse> result = service.listParents();

        assertEquals(1, result.size());
        assertEquals(1L, result.getFirst().id());
        verify(categories).findByParentIsNull(any(Sort.class));
    }

    @Test
    void generatesSlugFromVietnameseName() {
        Category parent = new Category();
        parent.setId(1L);
        parent.setIsActive(true);
        when(categories.findByIdAndIsActiveTrue(1L)).thenReturn(Optional.of(parent));
        when(categories.save(any(Category.class))).thenAnswer(call -> call.getArgument(0));

        CategoryResponse result = service.create(new CreateCategoryRequest("Áo Đẹp Nam", 1L, true));

        assertEquals("ao-dep-nam", result.slug());
    }
}
