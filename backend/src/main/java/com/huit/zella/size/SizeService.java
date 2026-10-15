package com.huit.zella.size;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.enums.SizeEnum;
import com.huit.zella.productvariant.ProductVariantRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SizeService {
    SizeRepository sizeRepository;
    ProductVariantRepository productVariantRepository;

    @Transactional(readOnly = true)
    public List<SizeResponse> list() {
        return sizeRepository.findAll(Sort.by("displayOrder", "id"))
                .stream().map(SizeResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public SizeResponse get(Integer id) {
        return SizeResponse.from(requireSize(id));
    }

    @Transactional
    public SizeResponse create(CreateSizeRequest request) {
        String name = sizeName(request.name());
        if (sizeRepository.existsByNameIgnoreCase(name)) {
            throw new BusinessException(HttpStatus.CONFLICT, "SIZE_ALREADY_EXISTS", "Size already exists");
        }
        Size size = new Size();
        size.setName(name);
        size.setDisplayOrder(request.displayOrder());
        return SizeResponse.from(sizeRepository.save(size));
    }

    @Transactional
    public SizeResponse update(Integer id, CreateSizeRequest request) {
        Size size = requireSize(id);
        String name = sizeName(request.name());
        if (sizeRepository.existsByNameIgnoreCaseAndIdNot(name, id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "SIZE_ALREADY_EXISTS", "Size already exists");
        }
        size.setName(name);
        size.setDisplayOrder(request.displayOrder());
        return SizeResponse.from(sizeRepository.save(size));
    }

    @Transactional
    public void delete(Integer id) {
        Size size = requireSize(id);
        if (productVariantRepository.existsBySizeId(id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "SIZE_IN_USE", "Size is used by a product variant");
        }
        sizeRepository.delete(size);
    }

    private Size requireSize(Integer id) {
        return sizeRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "SIZE_NOT_FOUND", "Size not found"));
    }

    private String sizeName(String value) {
        if (value == null || value.isBlank()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_SIZE_NAME", "Size name is required");
        }
        try {
            return SizeEnum.valueOf(value.trim().toUpperCase(Locale.ROOT)).name();
        } catch (IllegalArgumentException ex) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_SIZE_NAME",
                    "Size name must be one of XS, S, M, L, XL, XXL");
        }
    }
}
