package com.huit.zella.product;

import org.junit.jupiter.api.Test;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class BoughtTogetherServiceTest {
    @Test void previewIncludesNamesForContextAndBothSidesOfDisplayedRules() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L,3L),Set.of(4L)));
        var card=mock(ProductCardResponse.class); when(card.id()).thenReturn(3L);
        when(products.featuredCards(anyList())).thenReturn(List.of(card));
        when(store.productNames(Set.of(1L,2L,3L))).thenReturn(Map.of(1L,"Áo",2L,"Quần",3L,"Giày"));
        var service=new BoughtTogetherService(store,products,Clock.systemUTC(),settings());
        var preview=service.preview(1L);
        assertEquals(List.of(1L),preview.contextProductIds());
        assertEquals("Áo",preview.productNames().get(1L));
        assertEquals("Quần",preview.productNames().get(2L));
        assertEquals("Giày",preview.productNames().get(3L));
        verify(store).productNames(Set.of(1L,2L,3L));
    }
    @Test void rejectsInvalidContextAndPagesMiningResults() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        var config=settings();
        var service=new BoughtTogetherService(store,products,Clock.systemUTC(),config);
        assertThrows(com.huit.zella.common.exception.BusinessException.class,()->service.get(List.of(),8));
        assertThrows(com.huit.zella.common.exception.BusinessException.class,()->service.get(List.of(-1L),8));
        assertThrows(com.huit.zella.common.exception.BusinessException.class,()->service.get(Collections.nCopies(51,1L),8));
        verifyNoInteractions(store,products);
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L,3L),Set.of(4L)));
        assertEquals(8,service.itemsets(0,2,0).totalElements());
        assertEquals(4,service.itemsets(0,2,0).totalPages());
        assertEquals(2,service.itemsets(1,2,0).content().size());
        assertTrue(service.itemsets(Integer.MAX_VALUE,100,0).content().isEmpty());
        assertThrows(com.huit.zella.common.exception.BusinessException.class,()->service.itemsets(0,20,-1));
    }
    @Test void contextUsesOnlySingleProductAntecedentsAndExcludesKnownProducts() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L,3L),Set.of(1L,2L,3L),Set.of(4L),Set.of(4L)));
        var card=mock(ProductCardResponse.class); when(card.id()).thenReturn(3L);
        when(products.featuredCards(anyList())).thenReturn(List.of(card));
        var service=new BoughtTogetherService(store,products,Clock.systemUTC(),settings());
        var result=service.get(List.of(1L,2L),8);
        assertEquals(1,result.products().size());
        var item=result.products().getFirst();
        assertEquals(List.of(1L),item.antecedent());
        assertEquals(List.of(2L,3L),item.consequent());
        assertEquals(1,item.confidence());
        assertEquals(2,item.lift());
        assertTrue(service.associationRules(0,100).content().stream().allMatch(r->r.antecedent().size()==1));
        assertTrue(service.get(List.of(1L,2L,3L),8).products().isEmpty());
    }

    @Test void oneOccurrenceCanBeFrequentAndLiftDoesNotFilterMiningResults() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        var settings=settings();
        when(settings.get()).thenReturn(config(true,"0.5","0.5","100",8));
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L,3L),Set.of(4L)));
        var service=new BoughtTogetherService(store,products,Clock.systemUTC(),settings);
        var status=service.status(false);
        assertEquals(1,status.minimumCount());
        assertEquals(3,status.maximumItemsetSize());
        assertEquals(8,status.frequentItemsets());
        assertEquals(9,status.totalRules());
        assertEquals(1,service.itemsets(0,10,3).totalElements());
        assertEquals(List.of(1L,2L,3L),service.itemsets(0,10,3).content().getFirst().items());
        assertEquals(9,service.associationRules(0,100).content().size());
        assertTrue(service.get(1L,8).products().isEmpty());
        verifyNoInteractions(products);
    }
    private BoughtTogetherSettingsService settings() {
        var settings=mock(BoughtTogetherSettingsService.class);
        when(settings.get()).thenReturn(config(true,"0.01","0.1","1",8));
        return settings;
    }
    private BoughtTogetherSettingsService.Settings config(boolean enabled,String support,String confidence,String lift,int limit) {
        return new BoughtTogetherSettingsService.Settings(180,new java.math.BigDecimal(support),new java.math.BigDecimal(confidence),new java.math.BigDecimal(lift),limit,enabled);
    }
    @Test void ranksRulesAndFiltersUnavailableProductsBeforeLimit() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        var now=Instant.parse("2026-10-17T00:00:00Z");
        var clock=Clock.fixed(now,ZoneOffset.UTC);
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L,3L),Set.of(1L,2L,3L),Set.of(4L),Set.of(4L)));
        var service=new BoughtTogetherService(store,products,clock,settings());
        when(products.featuredCards(List.of(2L,3L))).thenReturn(List.of());
        assertTrue(service.get(1L,1).products().isEmpty());
        var card=mock(ProductCardResponse.class);
        when(card.id()).thenReturn(3L);
        when(products.featuredCards(List.of(2L,3L))).thenReturn(List.of(card));
        var result=service.get(1L,1);
        assertEquals(1,result.products().size());
        assertSame(card,result.products().getFirst().product());
        assertEquals(0.5,result.products().getFirst().support());
        assertEquals(1.0,result.products().getFirst().confidence());
        assertEquals(2.0,result.products().getFirst().lift());
        assertEquals(4,service.get(1L,8).totalTransactions());
        assertTrue(service.get(999L,8).products().isEmpty());
        verify(store,times(1)).load(now.minus(Duration.ofDays(180)),now);
        verify(products,times(3)).featuredCards(List.of(2L,3L));
    }
    @Test void excludesIndependentProducts() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L),Set.of(1L,2L),Set.of(1L),Set.of(2L)));
        var service=new BoughtTogetherService(store,products,Clock.systemUTC(),settings());
        assertTrue(service.get(1L,8).products().isEmpty());
        verifyNoInteractions(products);
    }

    @Test void disabledPublicApiDoesNotMineButAdminCanInspect() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        var settings=settings();
        when(settings.get()).thenReturn(config(false,"0.01","0.1","1",8));
        var service=new BoughtTogetherService(store,products,Clock.systemUTC(),settings);
        assertTrue(service.get(1L,8).products().isEmpty());
        verifyNoInteractions(store,products);
        when(store.load(any(),any())).thenReturn(List.of());
        assertEquals("DISABLED",service.preview(1L).code());
    }

    @Test void configChangesAndExplicitRebuildRefreshMiningCache() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        var settings=settings();
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L),Set.of(1L,2L),Set.of(3L)));
        var service=new BoughtTogetherService(store,products,Clock.systemUTC(),settings);
        assertEquals(4,service.status(false).frequentItemsets());
        service.status(false);
        verify(store,times(1)).load(any(),any());
        when(settings.get()).thenReturn(config(true,"0.9","0.1","1",8));
        assertEquals(0,service.status(false).frequentItemsets());
        assertEquals(3,service.status(false).minimumCount());
        service.status(true);
        verify(store,times(3)).load(any(),any());
    }

    @Test void previewExplainsMissingHistorySupportAndConfidence() {
        var store=mock(BoughtTogetherStore.class);
        var products=mock(ProductService.class);
        var settings=settings();
        var service=new BoughtTogetherService(store,products,Clock.systemUTC(),settings);
        when(store.load(any(),any())).thenReturn(List.of());
        assertEquals("NO_TRANSACTIONS",service.preview(1L).code());
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L),Set.of(1L),Set.of(3L)));
        service.status(true);
        assertEquals("NO_PRODUCT_HISTORY",service.preview(9L).code());
        when(settings.get()).thenReturn(config(true,"0.5","0.1","1",8));
        assertEquals("BELOW_SUPPORT",service.preview(1L).code());
        when(settings.get()).thenReturn(config(true,"0.01","0.1","1",8));
        when(store.load(any(),any())).thenReturn(List.of(Set.of(1L,2L),Set.of(1L,2L),Set.of(1L),Set.of(3L)));
        service.status(true);
        when(settings.get()).thenReturn(config(true,"0.01","0.9","1",8));
        assertEquals("BELOW_RULE_THRESHOLDS",service.preview(1L).code());
        when(settings.get()).thenReturn(config(true,"0.01","0.1","1",8));
        when(products.featuredCards(List.of(2L))).thenReturn(List.of());
        assertEquals("NO_AVAILABLE_PRODUCTS",service.preview(1L).code());
    }
}
