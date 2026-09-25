package com.huit.zella.product;

import com.huit.zella.category.Category;
import com.huit.zella.category.CategoryRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.sizeguide.SizeGuide;
import com.huit.zella.sizeguide.SizeGuideRepository;
import com.huit.zella.supplier.Supplier;
import com.huit.zella.supplier.SupplierRepository;
import jakarta.persistence.EntityNotFoundException;
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

    @Transactional
    public ProductResponse create(CreateProductRequest request) {
        Category category = categoryRepository
                .findByIdAndIsActiveTrue(request.categoryId())
                .orElseThrow(() ->
                        new BusinessException(HttpStatus.CONFLICT, "CATEGORY_NOT_FOUND_OR_INACTIVE", "category not found or inactive"));

        Supplier supplier = supplierRepository
                .findByIdAndIsActiveTrue(request.supplierId())
                .orElseThrow(() ->
                        new BusinessException(HttpStatus.CONFLICT, "SUPPLIER_NOT_FOUND_OR_INACTIVE", "Supplier not found or inactive"));

        SizeGuide sizeGuide = sizeGuideRepository
                .findByIdAndIsActiveTrue(request.sizeGuideId())
                .orElseThrow(() ->
                        new BusinessException(HttpStatus.CONFLICT, "SIZEGUIDE_NOT_FOUND_OR_INACTIVE", "Sizeguide not found or inactive"));

        String name = request.name().trim();
        if (productRepository.existsByNameIgnoreCase(name)) {
            throw new BusinessException(HttpStatus.CONFLICT, "NAME_ALREADY_EXISTS", "Product name already exists");
        }

        String slug = Normalizer.normalize(request.name(), Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[đĐ]", "d")
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-|-$", "");

        if (productRepository.existsBySlugIgnoreCase(slug)) {
            slug = slug + "-" + System.currentTimeMillis();
        }


        String description = request.description().trim().toLowerCase(Locale.ROOT);

        String style = request.style().trim().toLowerCase(Locale.ROOT);

        String occasion = request.occasion().trim().toLowerCase(Locale.ROOT);

        if (request.basePrice() == null ||
                request.basePrice().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(HttpStatus.BAD_REQUEST,"PRICE_MUST_BE_GREATER_THAN_0","price must be greater than 0");
        }

        Product product = new Product();
        product.setCategory(category);
        product.setSupplier(supplier);
        product.setSizeGuide(sizeGuide);
        product.setName(name);
        product.setSlug(slug);
        product.setDescription(description);
        product.setStyle(style);
        product.setOccasion(occasion);
        product.setBasePrice(request.basePrice());

        return ProductResponse.createProductResponse(productRepository.save(product));
    }

    @Transactional(readOnly = true)
    public Page<ProductResponse> list(String query, Pageable pageable) {
        Page<Product> page = query == null || query.isBlank()
                ? productRepository.findAll(pageable)
                : productRepository.findByNameContainingIgnoreCase(query.trim(), pageable);
        return page.map(ProductResponse::createProductResponse);
    }

    @Transactional(readOnly = true)
    public ProductResponse get(Long id) {
        return ProductResponse.createProductResponse(requireFeature(id));
    }


    @Transactional
    public ProductResponse update(Long id, CreateProductRequest request) {
        Product feature = requireFeature(id);
        Category category = categoryRepository
                .findByIdAndIsActiveTrue(request.categoryId())
                .orElseThrow(() ->
                        new BusinessException(HttpStatus.CONFLICT, "CATEGORY_NOT_FOUND_OR_INACTIVE", "category not found or inactive"));

        Supplier supplier = supplierRepository
                .findByIdAndIsActiveTrue(request.supplierId())
                .orElseThrow(() ->
                        new BusinessException(HttpStatus.CONFLICT, "SUPPLIER_NOT_FOUND_OR_INACTIVE", "Supplier not found or inactive"));

        SizeGuide sizeGuide = sizeGuideRepository
                .findByIdAndIsActiveTrue(request.sizeGuideId())
                .orElseThrow(() ->
                        new BusinessException(HttpStatus.CONFLICT, "SIZEGUIDE_NOT_FOUND_OR_INACTIVE", "Sizeguide not found or inactive"));

        String name = request.name().trim();
        if (productRepository.existsByNameIgnoreCaseAndIdNot(name,id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "NAME_ALREADY_EXISTS", "Product name already exists");
        }

        String slug = Normalizer.normalize(request.name(), Normalizer.Form.NFD)
                .replaceAll("\\p{InCombiningDiacriticalMarks}+", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[đĐ]", "d")
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("^-|-$", "");

        if(productRepository.existsBySlugIgnoreCaseAndIdNot(slug,id)) {
            slug = slug + "-" + System.currentTimeMillis();
        }

        String description = request.description().trim().toLowerCase(Locale.ROOT);

        String style = request.style().trim().toLowerCase(Locale.ROOT);

        String occasion = request.occasion().trim().toLowerCase(Locale.ROOT);

        if (request.basePrice() == null ||
                request.basePrice().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BusinessException(HttpStatus.BAD_REQUEST,"PRICE_MUST_BE_GREATER_THAN_0","price must be greater than 0");
        }

        boolean isActive = request.isActive();

        feature.setCategory(category);
        feature.setSupplier(supplier);
        feature.setSizeGuide(sizeGuide);
        feature.setName(name);
        feature.setSlug(slug);
        feature.setDescription(description);
        feature.setStyle(style);
        feature.setOccasion(occasion);
        feature.setBasePrice(request.basePrice());
        feature.setActive(isActive);

        return ProductResponse.createProductResponse(productRepository.save(feature));
    }

//    @Transactional
//    public void delete(Long id) {
//        Product product = requireFeature(id);
//        productRepository.delete(product);
//    }

    private Product requireFeature(Long id) {
        return productRepository.findById(id).orElseThrow(() -> new BusinessException(
                HttpStatus.NOT_FOUND, "ID_NOT_FOUND", "ID not found"
        ));
    }

}
