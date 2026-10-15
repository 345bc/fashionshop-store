package com.huit.zella.size;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productvariant.ProductVariantRepository;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class SizeServiceTest {
    private final SizeRepository sizes = mock(SizeRepository.class);
    private final ProductVariantRepository variants = mock(ProductVariantRepository.class);
    private final SizeService service = new SizeService(sizes, variants);

    @Test
    void rejectsDuplicateNameAfterTrimming() {
        when(sizes.existsByNameIgnoreCase("XL")).thenReturn(true);

        BusinessException error = assertThrows(BusinessException.class,
                () -> service.create(new CreateSizeRequest(" XL ", 3)));

        assertEquals(HttpStatus.CONFLICT, error.getStatus());
        assertEquals("SIZE_ALREADY_EXISTS", error.getCode());
        verify(sizes, never()).save(any());
    }

    @Test
    void savesCanonicalNameFromEnum() {
        when(sizes.save(any(Size.class))).thenAnswer(call -> call.getArgument(0));

        SizeResponse result = service.create(new CreateSizeRequest(" xl ", 3));

        assertEquals("XL", result.name());
        verify(sizes).existsByNameIgnoreCase("XL");
    }

    @Test
    void rejectsNameOutsideEnumOnCreate() {
        BusinessException error = assertThrows(BusinessException.class,
                () -> service.create(new CreateSizeRequest("FREE", 0)));

        assertEquals(HttpStatus.BAD_REQUEST, error.getStatus());
        assertEquals("INVALID_SIZE_NAME", error.getCode());
        verify(sizes, never()).save(any());
    }

    @Test
    void rejectsNameOutsideEnumOnUpdate() {
        Size size = new Size();
        size.setId(2);
        when(sizes.findById(2)).thenReturn(Optional.of(size));

        BusinessException error = assertThrows(BusinessException.class,
                () -> service.update(2, new CreateSizeRequest("4XL", 4)));

        assertEquals("INVALID_SIZE_NAME", error.getCode());
        verify(sizes, never()).save(any());
    }

    @Test
    void cannotDeleteSizeUsedByVariant() {
        Size size = new Size();
        size.setId(2);
        when(sizes.findById(2)).thenReturn(Optional.of(size));
        when(variants.existsBySizeId(2)).thenReturn(true);

        BusinessException error = assertThrows(BusinessException.class, () -> service.delete(2));

        assertEquals("SIZE_IN_USE", error.getCode());
        verify(sizes, never()).delete(any());
    }
}
