package com.huit.zella.color;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productvariant.ProductVariantRepository;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class ColorServiceTest {
    private final ColorRepository colors = mock(ColorRepository.class);
    private final ProductVariantRepository variants = mock(ProductVariantRepository.class);
    private final ColorService service = new ColorService(colors, variants);

    @Test
    void rejectsDuplicateCodeIgnoringCase() {
        when(colors.existsByCodeIgnoreCase("BLACK")).thenReturn(true);

        BusinessException error = assertThrows(BusinessException.class,
                () -> service.create(new CreateColorRequest("Black", "#000000", "black")));

        assertEquals("COLOR_CODE_ALREADY_EXISTS", error.getCode());
        verify(colors, never()).save(any());
    }

    @Test
    void cannotDeleteColorUsedByVariant() {
        Color color = new Color();
        color.setId(3);
        when(colors.findById(3)).thenReturn(Optional.of(color));
        when(variants.existsByColorId(3)).thenReturn(true);

        BusinessException error = assertThrows(BusinessException.class, () -> service.delete(3));

        assertEquals("COLOR_IN_USE", error.getCode());
        verify(colors, never()).delete(any());
    }
}
