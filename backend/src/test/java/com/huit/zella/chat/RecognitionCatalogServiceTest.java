package com.huit.zella.chat;

import com.huit.zella.product.ProductService;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class RecognitionCatalogServiceTest {
    @Test void catalogShadesBelongToOneExplicitGroup() {
        assertTrue(RecognitionCatalogService.colorKeywords("Pink").contains("rose"));
        assertTrue(RecognitionCatalogService.colorKeywords("Purple").contains("periwinkle"));
        assertTrue(RecognitionCatalogService.colorKeywords("Blue").contains("ice blue"));
        assertTrue(RecognitionCatalogService.colorKeywords("Grey").contains("blue gray"));
        assertFalse(RecognitionCatalogService.colorKeywords("Blue").contains("blue gray"));
        assertTrue(RecognitionCatalogService.colorKeywords("Green").contains("light green"));
        assertTrue(RecognitionCatalogService.colorKeywords("Brown").contains("tan"));
    }
    @Test void paletteUsesProvidedGroupsAndCreamBelongsToWhite() {
        for (String color : List.of("Black", "White", "Grey", "Blue", "Green", "Red", "Pink", "Purple", "Yellow", "Orange", "Brown", "Beige", "Multi"))
            assertFalse(RecognitionCatalogService.colorKeywords(color).isEmpty(), color);
        assertTrue(RecognitionCatalogService.colorKeywords("White").contains("cream"));
        assertFalse(RecognitionCatalogService.colorKeywords("Beige").contains("cream"));
        assertFalse(RecognitionCatalogService.colorKeywords("Beige").contains("kem"));
        assertEquals(RecognitionCatalogService.colorKeywords("Blue"), RecognitionCatalogService.colorKeywords("Teal"));
        assertTrue(RecognitionCatalogService.colorKeywords("Grey").contains("charcoal"));
        assertTrue(RecognitionCatalogService.colorKeywords("Beige").contains("peach"));
    }
    private ImageRecognitionService.Detection detection(String label, String color) {
        return new ImageRecognitionService.Detection(label, .9, List.of(),
                List.of(new ImageRecognitionService.Color(color, .9)));
    }

    @Test void allModelClassesHaveKeywordsAndDressDoesNotUseGenericSkirtKeyword() {
        for (String label : List.of("Blazer", "Blouse", "Button-Down", "Cardigan", "Hoodie", "Jacket", "Sweater", "Tank", "Tee", "Jeans", "Joggers", "Leggings", "Shorts", "Skirt", "Sweatpants", "Coat", "Dress"))
            assertFalse(RecognitionCatalogService.keywords(label).isEmpty(), label);
        assertFalse(RecognitionCatalogService.keywords("Dress").contains("váy"));
        assertTrue(RecognitionCatalogService.keywords("unknown").isEmpty());
        assertTrue(RecognitionCatalogService.colorKeywords("beige").contains("beige"));
    }

    @Test void colorFallbackIsExplicitAndMatchingRequiresAvailableStockOnSameVariant() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        ProductService products = mock(ProductService.class);
        when(jdbc.query(anyString(), org.mockito.ArgumentMatchers.<RowMapper<Long>>any(), any(Object[].class)))
                .thenReturn(List.of(), List.of(7L));
        when(products.featuredCards(List.of(7L))).thenReturn(List.of());
        var result = new RecognitionCatalogService(jdbc, products).suggest(List.of(detection("Blazer", "beige")));
        assertEquals(1, result.size());
        assertFalse(result.getFirst().colorMatched());
        verify(products).featuredCards(List.of(7L));
        verify(jdbc).query(contains("LOWER(LTRIM(RTRIM(col.name))) IN"), org.mockito.ArgumentMatchers.<RowMapper<Long>>any(), any(Object[].class));
        verify(jdbc, times(2)).query(contains("v.stock_quantity>v.reserved_quantity"), org.mockito.ArgumentMatchers.<RowMapper<Long>>any(), any(Object[].class));
    }

    @Test void unknownLabelsDoNotReturnUnrelatedProducts() {
        JdbcTemplate jdbc = mock(JdbcTemplate.class);
        ProductService products = mock(ProductService.class);
        assertTrue(new RecognitionCatalogService(jdbc, products).suggest(List.of(detection("unknown", "white"))).isEmpty());
        verifyNoInteractions(jdbc, products);
    }
}
