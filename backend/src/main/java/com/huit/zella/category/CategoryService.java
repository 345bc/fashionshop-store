package com.huit.zella.category;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.ProductRepository;
import com.huit.zella.productimage.ProductImageFileStorage;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.Objects;

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
@Slf4j
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CategoryService {
    CategoryRepository categoryRepository;
    ProductRepository productRepository;
    ProductImageFileStorage fileStorage;

    @Transactional(readOnly = true)
    public List<CategoryResponse> listParents() {
        return categoryRepository.findByParentIsNull(Sort.by("name", "id"))
                .stream()
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public Page<CategoryResponse> list(String query, Boolean active, Pageable pageable) {
        String q = query == null ? "" : query.trim();
        Page<Category> page = categoryRepository.search(q, active, pageable);
        return page.map(CategoryResponse::from);
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> listByParent(Long parentId) {
        return categoryRepository.findByParentId(parentId, Sort.by("name", "id"))
                .stream().map(CategoryResponse::from).toList();
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
        Category category = requireCategoryForUpdate(id);
        String oldImage = category.getImageUrl();
        apply(category, request);
        CategoryResponse response = CategoryResponse.from(categoryRepository.save(category));
        if (!Objects.equals(oldImage, category.getImageUrl())) scheduleImageDeletion(oldImage);
        return response;
    }

    @Transactional
    public void delete(Long id) {
        Category category = requireCategoryForUpdate(id);
        if (categoryRepository.existsByParentId(id) || productRepository.existsByCategoryId(id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "CATEGORY_IN_USE", "Category has children or products");
        }
        categoryRepository.delete(category);
        scheduleImageDeletion(category.getImageUrl());
    }

    @Transactional
    public CategoryResponse replaceImage(Long id, String imageUrl) {
        Category category = requireCategoryForUpdate(id);
        String oldImage = category.getImageUrl();
        category.setImageUrl(imageUrl);
        CategoryResponse response = CategoryResponse.from(categoryRepository.save(category));
        if (!Objects.equals(oldImage, imageUrl)) scheduleImageDeletion(oldImage);
        return response;
    }

    private void scheduleImageDeletion(String url) {
        if (url == null || !url.startsWith(fileStorage.categoryPublicUrlPrefix())) return;
        String fileName = url.substring(fileStorage.categoryPublicUrlPrefix().length());
        if (!fileName.matches("[0-9a-f-]{36}\\.(jpg|png|gif|webp)")) return;
        Runnable delete = () -> {
            try {
                fileStorage.deleteCategory(fileName);
            } catch (RuntimeException error) {
                log.warn("Could not delete category image {}", fileName, error);
            }
        };
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    delete.run();
                }
            });
        } else {
            delete.run();
        }
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
        category.setImageUrl(request.imageUrl());
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

    private Category requireCategoryForUpdate(Long id) {
        return categoryRepository.findByIdForImageUpdate(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "CATEGORY_NOT_FOUND", "Category not found"));
    }
}
