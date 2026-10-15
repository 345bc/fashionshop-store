package com.huit.zella.variantimage;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.productvariant.ProductVariantRepository;
import com.huit.zella.productimage.ProductImageFileStorage;
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
public class VariantImageService {
    private static final Logger log = LoggerFactory.getLogger(VariantImageService.class);
    VariantImageRepository imageRepository;
    ProductVariantRepository variantRepository;
    ProductImageFileStorage fileStorage;

    @Transactional(readOnly = true)
    public List<VariantImageResponse> list(Long variantId) {
        requireVariant(variantId);
        return imageRepository.findByVariantIdOrderByDisplayOrderAscIdAsc(variantId)
                .stream().map(VariantImageResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public VariantImageResponse get(Long id) {
        return VariantImageResponse.from(requireImage(id));
    }

    @Transactional
    public VariantImageResponse create(CreateVariantImageRequest request) {
        VariantImage image = new VariantImage();
        image.setVariant(requireVariantForUpdate(request.variantId()));
        apply(image, request);
        return VariantImageResponse.from(imageRepository.save(image));
    }

    @Transactional
    public VariantImageResponse update(Long id, CreateVariantImageRequest request) {
        VariantImage image = requireImage(id);
        image.setVariant(requireVariantForUpdate(request.variantId()));
        apply(image, request);
        return VariantImageResponse.from(imageRepository.save(image));
    }

    @Transactional
    public void delete(Long id) {
        VariantImage image = requireImage(id);
        String imageUrl = image.getImageUrl();
        imageRepository.delete(image);
        String prefix = fileStorage.variantPublicUrlPrefix();
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
            fileStorage.deleteVariant(fileName);
        } catch (RuntimeException error) {
            log.warn("Could not delete stored variant image {}", fileName, error);
        }
    }

    private void apply(VariantImage image, CreateVariantImageRequest request) {
        if (request.isPrimary()) {
            imageRepository.findByVariantIdAndIsPrimaryTrue(request.variantId())
                    .filter(previous -> !previous.getId().equals(image.getId()))
                    .ifPresent(previous -> previous.setPrimary(false));
        }
        image.setImageUrl(request.imageUrl().trim());
        image.setPrimary(request.isPrimary());
        image.setDisplayOrder(request.displayOrder());
    }

    private ProductVariant requireVariant(Long id) {
        return variantRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_VARIANT_NOT_FOUND", "Product variant not found"));
    }

    private ProductVariant requireVariantForUpdate(Long id) {
        return variantRepository.findByIdForImageUpdate(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "PRODUCT_VARIANT_NOT_FOUND", "Product variant not found"));
    }

    private VariantImage requireImage(Long id) {
        return imageRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "VARIANT_IMAGE_NOT_FOUND", "Variant image not found"));
    }
}
