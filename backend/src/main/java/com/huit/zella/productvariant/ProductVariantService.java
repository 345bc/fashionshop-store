package com.huit.zella.productvariant;

import com.huit.zella.color.Color;
import com.huit.zella.color.ColorRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.Product;
import com.huit.zella.product.ProductRepository;
import com.huit.zella.size.Size;
import com.huit.zella.size.SizeRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ProductVariantService {
    ProductVariantRepository productVariantRepository;
    ProductRepository productRepository;
    SizeRepository sizeRepository;
    ColorRepository colorRepository;

    @Transactional(readOnly = true)
    public Page<ProductVariantResponse> list(String query, Long productId, Pageable pageable) {
        String normalizedQuery = query == null ? "" : query.trim();
        Page<ProductVariant> variants;
        if (productId != null && !normalizedQuery.isBlank()) {
            variants = productVariantRepository.findByProductIdAndSkuContainingIgnoreCase(
                    productId, normalizedQuery, pageable);
        } else if (productId != null) {
            variants = productVariantRepository.findByProductId(productId, pageable);
        } else if (!normalizedQuery.isBlank()) {
            variants = productVariantRepository.findBySkuContainingIgnoreCase(normalizedQuery, pageable);
        } else {
            variants = productVariantRepository.findAll(pageable);
        }
        return variants.map(ProductVariantResponse::from);
    }

    @Transactional(readOnly = true)
    public ProductVariantResponse get(Long id) {
        return ProductVariantResponse.from(requireVariant(id));
    }

    @Transactional
    public ProductVariantResponse create(CreateProductVariantRequest request) {
        ProductVariant variant = new ProductVariant();
        return save(variant, request, null);
    }

    @Transactional
    public ProductVariantResponse update(Long id, CreateProductVariantRequest request) {
        ProductVariant variant = requireVariant(id);
        return save(variant, request, id);
    }

    private ProductVariantResponse save(ProductVariant variant, CreateProductVariantRequest request, Long excludedId) {
        Product product = productRepository.findById(request.productId()).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found"));
        Size size = sizeRepository.findById(request.sizeId()).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "SIZE_NOT_FOUND", "Size not found"));
        Color color = colorRepository.findById(request.colorId()).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "COLOR_NOT_FOUND", "Color not found"));

        String sku = product.getSlug() + "-" + color.getCode() + "-" + size.getName();
        if (sku.length() > 100) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "SKU_TOO_LONG", "Generated SKU must not exceed 100 characters");
        }
        ensureUnique(sku, request.productId(), request.sizeId(), request.colorId(), excludedId);

        if (request.reservedQuantity() > request.stockQuantity()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_RESERVED_QUANTITY",
                    "Reserved quantity must not exceed stock quantity");
        }

        variant.setProduct(product);
        variant.setSku(sku);
        variant.setSize(size);
        variant.setColor(color);
        variant.setPrice(request.price());
        variant.setCostPrice(request.costPrice());
        variant.setStockQuantity(request.stockQuantity());
        variant.setReservedQuantity(request.reservedQuantity());
        variant.setActive(request.isActive() == null || request.isActive());
        return ProductVariantResponse.from(productVariantRepository.save(variant));
    }

    private void ensureUnique(String sku, Long productId, Integer sizeId, Integer colorId, Long excludedId) {
        boolean duplicateSku = excludedId == null
                ? productVariantRepository.existsBySkuIgnoreCase(sku)
                : productVariantRepository.existsBySkuIgnoreCaseAndIdNot(sku, excludedId);
        if (duplicateSku) {
            throw new BusinessException(HttpStatus.CONFLICT, "SKU_ALREADY_EXISTS", "SKU already exists");
        }

        boolean duplicateCombination = excludedId == null
                ? productVariantRepository.existsByProductIdAndSizeIdAndColorId(productId, sizeId, colorId)
                : productVariantRepository.existsByProductIdAndSizeIdAndColorIdAndIdNot(
                        productId, sizeId, colorId, excludedId);
        if (duplicateCombination) {
            throw new BusinessException(HttpStatus.CONFLICT, "VARIANT_ALREADY_EXISTS",
                    "A variant with this product, size and color already exists");
        }
    }
    private ProductVariant requireVariant(Long id) {
        return productVariantRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_VARIANT_NOT_FOUND", "Product variant not found"));
    }
}
