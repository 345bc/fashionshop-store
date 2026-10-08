package com.huit.zella.color;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productvariant.ProductVariantRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ColorService {
    ColorRepository colorRepository;
    ProductVariantRepository productVariantRepository;

    @Transactional(readOnly = true)
    public Page<ColorResponse> list(String query, Pageable pageable) {
        String q = query == null ? "" : query.trim();
        Page<Color> page = colorRepository.search(q, pageable);
        return page.map(ColorResponse::from);
    }

    @Transactional(readOnly = true)
    public ColorResponse get(Integer id) {
        return ColorResponse.from(requireColor(id));
    }

    @Transactional
    public ColorResponse create(CreateColorRequest request) {
        String code = request.code().trim().toUpperCase(Locale.ROOT);
        if (colorRepository.existsByCodeIgnoreCase(code)) {
            throw new BusinessException(HttpStatus.CONFLICT, "COLOR_CODE_ALREADY_EXISTS", "Color code already exists");
        }
        Color color = new Color();
        apply(color, request, code);
        return ColorResponse.from(colorRepository.save(color));
    }

    @Transactional
    public ColorResponse update(Integer id, CreateColorRequest request) {
        Color color = requireColor(id);
        String code = request.code().trim().toUpperCase(Locale.ROOT);
        if (colorRepository.existsByCodeIgnoreCaseAndIdNot(code, id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "COLOR_CODE_ALREADY_EXISTS", "Color code already exists");
        }
        apply(color, request, code);
        return ColorResponse.from(colorRepository.save(color));
    }

    @Transactional
    public void delete(Integer id) {
        Color color = requireColor(id);
        if (productVariantRepository.existsByColorId(id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "COLOR_IN_USE", "Color is used by a product variant");
        }
        colorRepository.delete(color);
    }

    private void apply(Color color, CreateColorRequest request, String code) {
        color.setName(request.name().trim());
        color.setHexCode(request.hexCode() == null || request.hexCode().isEmpty()
                ? null : request.hexCode().toUpperCase(Locale.ROOT));
        color.setCode(code);
    }

    private Color requireColor(Integer id) {
        return colorRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "COLOR_NOT_FOUND", "Color not found"));
    }
}
