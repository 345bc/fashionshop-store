package com.huit.zella.product;

import com.huit.zella.category.Category;
import com.huit.zella.category.CategoryRepository;
import com.huit.zella.color.Color;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productimage.ProductImage;
import com.huit.zella.productimage.ProductImageRepository;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.productvariant.ProductVariantRepository;
import com.huit.zella.sizeguide.SizeGuide;
import com.huit.zella.sizeguide.SizeGuideRepository;
import com.huit.zella.supplier.Supplier;
import com.huit.zella.supplier.SupplierRepository;
import com.huit.zella.variantimage.VariantImageRepository;
import com.huit.zella.variantimage.VariantImage;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.text.Normalizer;
import java.util.*;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ProductService {
    ProductRepository productRepository;
    CategoryRepository categoryRepository;
    SupplierRepository supplierRepository;
    SizeGuideRepository sizeGuideRepository;
    ProductImageRepository productImageRepository;
    ProductVariantRepository productVariantRepository;
    VariantImageRepository variantImageRepository;

    @Transactional(readOnly = true)
    public Page<ProductCardResponse> listCards(
            String query,
            Long categoryId,
            List<Integer> colorIds,
            List<Integer> sizeIds,
            Pageable pageable
    ) {
        String q = query == null ? "" : query.trim();

        boolean filterColors = colorIds != null && !colorIds.isEmpty();
        List<Integer> safeColorIds = filterColors ? colorIds : List.of(-1);

        boolean filterSizes = sizeIds != null && !sizeIds.isEmpty();
        List<Integer> safeSizeIds = filterSizes ? sizeIds : List.of(-1);

        Page<Product> page = productRepository.searchCards(
                q,
                categoryId,
                filterColors,
                safeColorIds,
                sizeIds,
                pageable
        );

        if (page.isEmpty()) {
            return new PageImpl<>(List.of(), pageable, page.getTotalElements());
        }

        List<Long> ids = page.getContent().stream()
                .map(Product::getId)
                .toList();

        Map<Long, String> images = new HashMap<>();

        for (ProductImage image :
                productImageRepository
                        .findByProductIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(ids)) {
            images.putIfAbsent(
                    image.getProduct().getId(),
                    image.getImageUrl()
            );
        }

        List<ProductVariant> variants = productVariantRepository.findCardVariants(ids);
        List<Long> variantIds = variants.stream().map(ProductVariant::getId).toList();
        Map<Long, String> variantImages = new HashMap<>();

        if (!variantIds.isEmpty()) {
            for (VariantImage image : variantImageRepository
                    .findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(variantIds)) {
                variantImages.putIfAbsent(image.getVariant().getId(), image.getImageUrl());
            }
        }

        Map<Long, Map<Integer, ProductCardResponse.ColorItem>> colors = new HashMap<>();

        for (ProductVariant variant : variants) {
            Color color = variant.getColor();
            Map<Integer, ProductCardResponse.ColorItem> productColors = colors.computeIfAbsent(
                    variant.getProduct().getId(), id -> new LinkedHashMap<>());
            ProductCardResponse.ColorItem existing = productColors.get(color.getId());
            String imageUrl = variantImages.get(variant.getId());

            // The same color can have several sizes. Keep the first variant with an image.
            if (existing == null || (existing.imageUrl() == null && imageUrl != null)) {
                productColors.put(color.getId(), new ProductCardResponse.ColorItem(
                        color.getId(), color.getName(), color.getHexCode(), imageUrl));
            }
        }

        return page.map(product -> new ProductCardResponse(
                product.getId(),
                product.getName(),
                product.getSlug(),
                product.getBasePrice(),
                images.get(product.getId()),
                new ArrayList<>(
                        colors.getOrDefault(product.getId(), Map.of()).values()
                )
        ));

    }


    @Transactional(readOnly = true)
    public Page<ProductResponse> list(String query, Long categoryId, Pageable pageable) {
        boolean hasQuery = query != null && !query.isBlank();
        Page<Product> page;
        if (categoryId == null) {
            page = hasQuery
                    ? productRepository.findByNameContainingIgnoreCase(query.trim(), pageable)
                    : productRepository.findAll(pageable);
        } else {
            page = hasQuery
                    ? productRepository.findByCategoryIdAndNameContainingIgnoreCase(categoryId, query.trim(), pageable)
                    : productRepository.findByCategoryId(categoryId, pageable);
        }
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
