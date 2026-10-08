package com.huit.zella.product;

import com.huit.zella.category.Category;
import com.huit.zella.category.CategoryRepository;
import com.huit.zella.color.Color;
import com.huit.zella.common.api.PageResponse;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.enums.BadgeEnum;
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
import java.time.Instant;
import java.time.temporal.ChronoUnit;
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
            BigDecimal minPrice,
            BigDecimal maxPrice,
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
                filterSizes,
                safeSizeIds,
                minPrice,
                maxPrice,
                pageable
        );

        return toCardPage(page,null);
    }

    @Transactional(readOnly = true)
    public Page<ProductCardResponse> listNewArrivals(Pageable pageable) {
        Instant now = Instant.now();
        Page<Product> page = productRepository.findNewArrivals(
                now.minus(7, ChronoUnit.DAYS), now, pageable
        );
        return toCardPage(page,null);
    }

    @Transactional(readOnly = true)
    public Page<ProductCardResponse> listProductSimilar(Long productId, Pageable pageable) {
        Product product = requireProduct(productId);
        BigDecimal price = product.getBasePrice();
        BigDecimal minPrice = price.multiply(new BigDecimal("0.70"));
        BigDecimal maxPrice = price.multiply(new BigDecimal("1.30"));
        Page<Product> page = productRepository.getProductsSimilar(
                product.getCategory().getId(),
                product.getId(),
                price,
                minPrice,
                maxPrice,
                pageable

        );
        return toCardPage(page, BadgeEnum.Similar.name());
    }

    private Page<ProductCardResponse> toCardPage(Page<Product> page,String badgeOverride) {
        if (page.isEmpty()) {
            return new PageImpl<>(List.of(), page.getPageable(), page.getTotalElements());
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

        Instant badgeNow = Instant.now();
        Instant newProductFrom = badgeNow.minus(7, ChronoUnit.DAYS);
        return page.map(product -> new ProductCardResponse(
                product.getId(),
                product.getName(),
                product.getSlug(),
                product.getBasePrice(),
                images.get(product.getId()),
                new ArrayList<>(
                        colors.getOrDefault(product.getId(), Map.of()).values()
                ),
                badgeOverride != null
                        ? badgeOverride
                        : product.getCreatedAt() != null
                        && !product.getCreatedAt().isBefore(newProductFrom)
                        && !product.getCreatedAt().isAfter(badgeNow)
                          ? BadgeEnum.New.name()
                          : null
        ));

    }

    @Transactional(readOnly = true)
    public ProductDetailResponse getProductDetail(String slug) {
        Product product = productRepository.findBySlugWithDetails(slug)
                .orElseThrow(() -> new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found"));

        List<ProductImage> images = productImageRepository.findByProductIdOrderByDisplayOrderAscIdAsc(product.getId());
        List<ProductVariant> variants = productVariantRepository.findDetailVariants(product.getId());


        List<ProductDetailResponse.SizeItem> sizeItems = variants.stream()
                .map(ProductVariant::getSize)
                .distinct()
                .map(s -> new ProductDetailResponse.SizeItem(s.getId(), s.getName()))
                .toList();

        List<Long> variantIds = variants.stream().map(ProductVariant::getId).toList();
        // We get variant images next

        Map<Integer, ProductDetailResponse.ColorItem> colorMap = new LinkedHashMap<>();
        for (ProductVariant variant : variants) {
            Color color = variant.getColor();
            colorMap.putIfAbsent(color.getId(), new ProductDetailResponse.ColorItem(
                    color.getId(), color.getName(), color.getHexCode()
            ));
        }
        List<ProductDetailResponse.ColorItem> colorItems = new ArrayList<>(colorMap.values());

        // Group variant images
        Map<Long, List<ProductDetailResponse.ImageItem>> variantImagesListMap = new HashMap<>();
        if (!variantIds.isEmpty()) {
            for (VariantImage image : variantImageRepository
                    .findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(variantIds)) {
                variantImagesListMap.computeIfAbsent(image.getVariant().getId(), k -> new ArrayList<>())
                        .add(new ProductDetailResponse.ImageItem(
                                image.getId(), image.getImageUrl(), image.isPrimary(), image.getDisplayOrder()
                        ));
            }
        }

        List<ProductDetailResponse.VariantItem> variantItems = variants.stream()
                .map(v -> new ProductDetailResponse.VariantItem(
                        v.getId(),
                        v.getSku(),
                        v.getColor().getId(),
                        v.getSize().getId(),
                        v.getPrice(),
                        v.getStockQuantity() - v.getReservedQuantity(),
                        variantImagesListMap.getOrDefault(v.getId(), List.of())
                ))
                .toList();

        // Stub out reviews for now
        BigDecimal averageRating = BigDecimal.ZERO;
        long reviewsCount = 0;
        PageResponse<ProductDetailResponse.ReviewItem> reviews = null;

        return new ProductDetailResponse(
                product.getId(),
                product.getName(),
                product.getSlug(),
                product.getDescription(),
                product.getStyle(),
                product.getOccasion(),
                product.getBasePrice(),
                product.getCategory() != null ? product.getCategory().getName() : null,
                product.getSizeGuide() != null ? product.getSizeGuide().getGuideImageUrl() : null,
                colorItems,
                sizeItems,
                variantItems,
                averageRating,
                reviewsCount,
                reviews
        );
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
