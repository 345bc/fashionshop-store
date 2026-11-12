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
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

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
        var ids = variants.getContent().stream().map(ProductVariant::getId).toList();
        Set<Long> orderedIds = ids.isEmpty() ? Set.of()
                : new HashSet<>(productVariantRepository.findVariantIdsWithOrders(ids));
        return variants.map(variant -> ProductVariantResponse.from(variant, orderedIds.contains(variant.getId())));
    }

    @Transactional(readOnly = true)
    public ProductVariantResponse get(Long id) {
        return ProductVariantResponse.from(requireVariant(id), hasOrders(id));
    }

    @Transactional
    public ProductVariantResponse create(CreateProductVariantRequest request) {
        ProductVariant variant = new ProductVariant();
        return save(variant, request, null);
    }

    @Transactional
    public ProductVariantResponse update(Long id, CreateProductVariantRequest request) {
        ProductVariant variant = productVariantRepository.findByIdForInventoryUpdate(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_VARIANT_NOT_FOUND", "Product variant not found"));
        return save(variant, request, id);
    }

    @Transactional
    public void delete(Long id) {
        try {
            if (productVariantRepository.deleteWithoutOrders(id) > 0) return;
        } catch (DataIntegrityViolationException ex) {
            throw new BusinessException(HttpStatus.CONFLICT, "VARIANT_IN_USE",
                    "Biến thể còn liên kết với dữ liệu khác, không thể xóa. Bạn có thể ẩn biến thể.");
        }
        requireVariant(id);
        throw new BusinessException(HttpStatus.CONFLICT, "VARIANT_HAS_ORDERS",
                "Biến thể đã có đơn hàng, không thể xóa.");
    }

    private boolean hasOrders(Long id) {
        return !productVariantRepository.findVariantIdsWithOrders(List.of(id)).isEmpty();
    }

    private ProductVariantResponse save(ProductVariant variant, CreateProductVariantRequest request, Long excludedId) {
        if (!request.stockQuantity().equals(variant.getStockQuantity())
                || !request.reservedQuantity().equals(variant.getReservedQuantity())) {
            throw new BusinessException(HttpStatus.CONFLICT, "INVENTORY_MANAGED_SEPARATELY",
                    "Tồn kho chỉ được thay đổi qua nhập hàng hoặc điều chỉnh kho");
        }
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
        variant.setStockQuantity(request.stockQuantity());
        variant.setReservedQuantity(request.reservedQuantity());
        variant.setActive(request.isActive() == null || request.isActive());
        return ProductVariantResponse.from(productVariantRepository.save(variant),
                excludedId != null && hasOrders(excludedId));
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
