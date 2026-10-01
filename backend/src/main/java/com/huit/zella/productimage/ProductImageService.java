package com.huit.zella.productimage;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.Product;
import com.huit.zella.product.ProductRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ProductImageService {
    private static final Logger log = LoggerFactory.getLogger(ProductImageService.class);
    ProductImageRepository imageRepository;
    ProductRepository productRepository;
    ProductImageFileStorage fileStorage;

    @Transactional(readOnly = true)
    public List<ProductImageResponse> list(Long productId) {
        requireProduct(productId);
        return imageRepository.findByProductIdOrderByDisplayOrderAscIdAsc(productId)
                .stream().map(ProductImageResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public ProductImageResponse get(Long id) {
        return ProductImageResponse.from(requireImage(id));
    }

    @Transactional
    public ProductImageResponse create(CreateProductImageRequest request) {
        ProductImage image = new ProductImage();
        image.setProduct(requireProductForUpdate(request.productId()));
        apply(image, request);
        return ProductImageResponse.from(imageRepository.save(image));
    }

    @Transactional
    public ProductImageResponse update(Long id, CreateProductImageRequest request) {
        ProductImage image = requireImage(id);
        image.setProduct(requireProductForUpdate(request.productId()));
        apply(image, request);
        return ProductImageResponse.from(imageRepository.save(image));
    }

    @Transactional
    public void delete(Long id) {
        ProductImage image = requireImage(id);
        String imageUrl = image.getImageUrl();
        imageRepository.delete(image);
        String prefix = fileStorage.publicUrlPrefix();
        if (imageUrl.startsWith(prefix)) {
            String fileName = imageUrl.substring(prefix.length());
            if (TransactionSynchronizationManager.isSynchronizationActive()) {
                TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                    @Override
                    public void afterCommit() {
                        deleteStoredFile(fileName);
                    }
                });
            } else {
                deleteStoredFile(fileName);
            }
        }
    }

    private void deleteStoredFile(String fileName) {
        try {
            fileStorage.delete(fileName);
        } catch (RuntimeException error) {
            log.warn("Could not delete R2 product image {}", fileName, error);
        }
    }

    private void apply(ProductImage image, CreateProductImageRequest request) {
        if (request.isPrimary()) {
            imageRepository.findByProductIdAndIsPrimaryTrue(request.productId())
                    .filter(previous -> !previous.getId().equals(image.getId()))
                    .ifPresent(previous -> previous.setPrimary(false));
        }
        image.setImageUrl(request.imageUrl().trim());
        image.setPrimary(request.isPrimary());
        image.setDisplayOrder(request.displayOrder());
    }

    private Product requireProduct(Long id) {
        return productRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found"));
    }

    private Product requireProductForUpdate(Long id) {
        return productRepository.findByIdForImageUpdate(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_NOT_FOUND", "Product not found"));
    }

    private ProductImage requireImage(Long id) {
        return imageRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_IMAGE_NOT_FOUND", "Product image not found"));
    }
}
