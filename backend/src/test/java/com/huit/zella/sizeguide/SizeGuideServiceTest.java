package com.huit.zella.sizeguide;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.ProductRepository;
import com.huit.zella.productimage.ProductImageFileStorage;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.*;

class SizeGuideServiceTest {
    private final SizeGuideRepository guides = mock(SizeGuideRepository.class);
    private final ProductRepository products = mock(ProductRepository.class);
    private final ProductImageFileStorage storage = mock(ProductImageFileStorage.class);
    private final SizeGuideService service = new SizeGuideService(guides, products, storage);

    @Test
    void cannotDeleteGuideUsedByProduct() {
        SizeGuide guide = new SizeGuide();
        guide.setId(4L);
        when(guides.findById(4L)).thenReturn(Optional.of(guide));
        when(products.existsBySizeGuideId(4L)).thenReturn(true);

        BusinessException error = assertThrows(BusinessException.class, () -> service.delete(4L));

        assertEquals("SIZE_GUIDE_IN_USE", error.getCode());
        verify(guides, never()).delete(any());
    }
}
