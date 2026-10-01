package com.huit.zella.product;

import com.huit.zella.category.Category;
import com.huit.zella.category.CategoryRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.sizeguide.SizeGuide;
import com.huit.zella.sizeguide.SizeGuideRepository;
import com.huit.zella.supplier.Supplier;
import com.huit.zella.supplier.SupplierRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ProductService {
    ProductRepository productRepository;
    CategoryRepository categoryRepository;
    SupplierRepository supplierRepository;
    SizeGuideRepository sizeGuideRepository;

    @Transactional(readOnly = true)
    public Page<ProductResponse> list(String query, Pageable pageable) {
        Page<Product> page = query == null || query.isBlank()
                ? productRepository.findAll(pageable)
                : productRepository.findByNameContainingIgnoreCase(query.trim(), pageable);
        return page.map(ProductResponse::from);
    }

    @Transactional(readOnly = true)
    public ProductResponse get(Long id) {
        return ProductResponse.from(requireProduct(id));
    }

    @Transactional
    public ProductResponse create(CreateProductRequest request) {
        Product product = new Product();
        apply(product, request);
        return ProductResponse.from(productRepository.save(product));
    }

    @Transactional
    public ProductResponse update(Long id, CreateProductRequest request) {
        Product product = requireProduct(id);
        apply(product, request);
        return ProductResponse.from(productRepository.save(product));
    }

    private void apply(Product product, CreateProductRequest request) {
        Category category = categoryRepository.findByIdAndIsActiveTrue(request.categoryId())
                .orElseThrow(() -> new BusinessException(HttpStatus.CONFLICT,
                        "CATEGORY_NOT_FOUND_OR_INACTIVE", "Category not found or inactive"));
        Supplier supplier = supplierRepository.findByIdAndIsActiveTrue(request.supplierId())
                .orElseThrow(() -> new BusinessException(HttpStatus.CONFLICT,
                        "SUPPLIER_NOT_FOUND_OR_INACTIVE", "Supplier not found or inactive"));
        SizeGuide sizeGuide = sizeGuideRepository.findByIdAndIsActiveTrue(request.sizeGuideId())
                .orElseThrow(() -> new BusinessException(HttpStatus.CONFLICT,
                        "SIZEGUIDE_NOT_FOUND_OR_INACTIVE", "Size guide not found or inactive"));

        String name = request.name().trim();
        boolean duplicateName = product.getId() == null
                ? productRepository.existsByNameIgnoreCase(name)
                : productRepository.existsByNameIgnoreCaseAndIdNot(name, product.getId());
        if (duplicateName) {
            throw new BusinessException(HttpStatus.CONFLICT, "NAME_ALREADY_EXISTS", "Product name already exists");
        }

        String slug = slugFromName(name);
        if (slug.isEmpty()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_PRODUCT_SLUG", "Product name cannot form a slug");
        }
        boolean duplicateSlug = product.getId() == null
                ? productRepository.existsBySlugIgnoreCase(slug)
                : productRepository.existsBySlugIgnoreCaseAndIdNot(slug, product.getId());
        if (duplicateSlug) {
            slug = slug + "-" + System.currentTimeMillis();
        }

        if (request.basePrice() == null || request.basePrice().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(HttpStatus.BAD_REQUEST,
                    "PRICE_MUST_BE_GREATER_THAN_0", "Price must be greater than 0");
        }

        product.setCategory(category);
        product.setSupplier(supplier);
        product.setSizeGuide(sizeGuide);
        product.setName(name);
        product.setSlug(slug);
        product.setDescription(normalizeOptional(request.description()));
        product.setStyle(normalizeOptional(request.style()));
        product.setOccasion(normalizeOptional(request.occasion()));
        product.setBasePrice(request.basePrice());
        product.setActive(request.isActive() == null || request.isActive());
    }

    private String slugFromName(String name) {
        return Normalizer.normalize(name, Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .toLowerCase(Locale.ROOT)
                .replace('đ', 'd')
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-|-$", "");
    }

    private String normalizeOptional(String value) {
        return value == null ? null : value.trim().toLowerCase(Locale.ROOT);
    }

    private Product requireProduct(Long id) {
        return productRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "ID_NOT_FOUND", "ID not found"));
    }
}
