package com.huit.zella.category;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.ProductRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.text.Normalizer;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CategoryService {
    CategoryRepository categoryRepository;
    ProductRepository productRepository;

    @Transactional(readOnly = true)
    public List<CategoryResponse> list(String query) {
        String q = query == null ? "" : query.trim().toLowerCase(Locale.ROOT);

        return categoryRepository
                .findByParentIsNotNull(Sort.by("name", "id"))
                .stream()
                .filter(category ->
                        q.isEmpty()
                                || category.getName().toLowerCase(Locale.ROOT).contains(q)
                                || category.getSlug().toLowerCase(Locale.ROOT).contains(q)
                )
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> listParents() {
        return categoryRepository.findByParentIsNull(Sort.by("name", "id"))
                .stream()
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public CategoryResponse get(Long id) {
        return CategoryResponse.from(requireCategory(id));
    }

    @Transactional
    public CategoryResponse create(CreateCategoryRequest request) {
        Category category = new Category();
        apply(category, request);
        return CategoryResponse.from(categoryRepository.save(category));
    }

    @Transactional
    public CategoryResponse update(Long id, CreateCategoryRequest request) {
        Category category = requireCategory(id);
        apply(category, request);
        return CategoryResponse.from(categoryRepository.save(category));
    }

    @Transactional
    public void delete(Long id) {
        Category category = requireCategory(id);
        if (categoryRepository.existsByParentId(id) || productRepository.existsByCategoryId(id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "CATEGORY_IN_USE", "Category has children or products");
        }
        categoryRepository.delete(category);
    }

    private void apply(Category category, CreateCategoryRequest request) {
        Category parent = null;
        if (request.parentId() != null) {
            parent = categoryRepository.findByIdAndIsActiveTrue(request.parentId()).orElseThrow(() ->
                    new BusinessException(HttpStatus.NOT_FOUND, "PARENT_CATEGORY_NOT_FOUND", "Active parent category not found"));
            for (Category ancestor = parent; ancestor != null; ancestor = ancestor.getParent()) {
                if (ancestor.getId().equals(category.getId())) {
                    throw new BusinessException(HttpStatus.BAD_REQUEST, "CATEGORY_CYCLE", "Category cannot be its own ancestor");
                }
            }
        }
        String name = request.name().trim();
        String slug = slugFromName(name);
        if (slug.isEmpty()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_CATEGORY_SLUG", "Category name cannot form a slug");
        }
        boolean duplicateSlug = category.getId() == null
                ? categoryRepository.existsBySlugIgnoreCase(slug)
                : categoryRepository.existsBySlugIgnoreCaseAndIdNot(slug, category.getId());
        if (duplicateSlug) {
            slug = slug + "-" + System.currentTimeMillis();
        }
        category.setName(name);
        category.setSlug(slug);
        category.setParent(parent);
        category.setIsActive(request.isActive() == null || request.isActive());
    }

    private String slugFromName(String name) {
        return Normalizer.normalize(name, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .toLowerCase(Locale.ROOT)
                .replace('đ', 'd')
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-|-$", "");
    }

    private Category requireCategory(Long id) {
        return categoryRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "CATEGORY_NOT_FOUND", "Category not found"));
    }
}
