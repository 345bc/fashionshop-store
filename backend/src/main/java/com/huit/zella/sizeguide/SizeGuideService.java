package com.huit.zella.sizeguide;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.ProductRepository;
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

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SizeGuideService {
    private static final Logger log = LoggerFactory.getLogger(SizeGuideService.class);
    SizeGuideRepository sizeGuideRepository;
    ProductRepository productRepository;
    ProductImageFileStorage fileStorage;

    @Transactional(readOnly = true)
    public Page<SizeGuideResponse> list(String query, Boolean active, Pageable pageable) {
        String q = query == null ? "" : query.trim();
        Page<SizeGuide> page = sizeGuideRepository.search(q, active, pageable);
        return page.map(SizeGuideResponse::from);
    }

    @Transactional(readOnly = true)
    public SizeGuideResponse get(Long id) {
        return SizeGuideResponse.from(requireSizeGuide(id));
    }

    @Transactional
    public SizeGuideResponse create(CreateSizeGuideRequest request) {
        SizeGuide guide = new SizeGuide();
        apply(guide, request);
        return SizeGuideResponse.from(sizeGuideRepository.save(guide));
    }

    @Transactional
    public SizeGuideResponse update(Long id, CreateSizeGuideRequest request) {
        SizeGuide guide = requireSizeGuide(id);
        String oldImageUrl = guide.getGuideImageUrl();
        apply(guide, request);
        SizeGuideResponse response = SizeGuideResponse.from(sizeGuideRepository.save(guide));
        if (oldImageUrl != null && !oldImageUrl.equals(guide.getGuideImageUrl())) {
            scheduleStoredImageDeletion(oldImageUrl);
        }
        return response;
    }

    @Transactional
    public void delete(Long id) {
        SizeGuide guide = requireSizeGuide(id);
        if (productRepository.existsBySizeGuideId(id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "SIZE_GUIDE_IN_USE", "Size guide is used by a product");
        }
        String oldImageUrl = guide.getGuideImageUrl();
        sizeGuideRepository.delete(guide);
        scheduleStoredImageDeletion(oldImageUrl);
    }

    @Transactional
    public SizeGuideResponse replaceImage(Long id, String imageUrl) {
        SizeGuide guide = requireSizeGuide(id);
        String oldImageUrl = guide.getGuideImageUrl();
        guide.setGuideImageUrl(imageUrl);
        SizeGuideResponse response = SizeGuideResponse.from(sizeGuideRepository.save(guide));
        if (!imageUrl.equals(oldImageUrl)) {
            scheduleStoredImageDeletion(oldImageUrl);
        }
        return response;
    }

    @Transactional
    public SizeGuideResponse removeImage(Long id) {
        SizeGuide guide = requireSizeGuide(id);
        String oldImageUrl = guide.getGuideImageUrl();
        guide.setGuideImageUrl(null);
        SizeGuideResponse response = SizeGuideResponse.from(sizeGuideRepository.save(guide));
        scheduleStoredImageDeletion(oldImageUrl);
        return response;
    }

    private void scheduleStoredImageDeletion(String imageUrl) {
        String prefix = fileStorage.sizeGuidePublicUrlPrefix();
        if (imageUrl == null || !imageUrl.startsWith(prefix)) return;
        String fileName = imageUrl.substring(prefix.length());
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override
                public void afterCommit() {
                    deleteStoredImage(fileName);
                }
            });
        } else {
            deleteStoredImage(fileName);
        }
    }

    private void deleteStoredImage(String fileName) {
        try {
            fileStorage.deleteSizeGuide(fileName);
        } catch (RuntimeException error) {
            log.warn("Could not delete stored size guide image {}", fileName, error);
        }
    }

    private void apply(SizeGuide guide, CreateSizeGuideRequest request) {
        guide.setName(request.name().trim());
        guide.setDescription(request.description() == null ? null : request.description().trim());
        guide.setGuideImageUrl(request.guideImageUrl() == null ? null : request.guideImageUrl().trim());
        guide.setIsActive(request.isActive() == null || request.isActive());
    }

    private SizeGuide requireSizeGuide(Long id) {
        return sizeGuideRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "SIZE_GUIDE_NOT_FOUND", "Size guide not found"));
    }
}
