package com.huit.zella.product;
import org.junit.jupiter.api.Test;
import java.time.*;
import java.math.BigDecimal;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class FeaturedProductTest {
    FeaturedProductStore.Observation observation(long id,long transactions,long quantity,long reviews,double rating) {
        return new FeaturedProductStore.Observation(id,transactions,quantity,reviews,rating);
    }
    ProductCardResponse card(long id) {return new ProductCardResponse(id,"Product "+id,"product-"+id,BigDecimal.TEN,null,null,"image",List.of(),null,null,0L);}
    @Test void supportCountsTransactionsNotUnitsAndCombinesNormalizedSalesWithBayesianRating() {
        var ranked=FeaturedProductService.rank(new FeaturedProductStore.Data(100,4,List.of(observation(1,25,80,20,5))));
        var first=ranked.getFirst();
        assertEquals(.25,first.support(),1e-9);assertEquals(80,first.netQuantity());
        assertEquals(140.0/30,first.adjustedRating(),1e-9);
        assertEquals(.6+.4*(140.0/30/5),first.score(),1e-9);
    }
    @Test void onePerfectReviewDoesNotBeatManyConsistentlyGoodReviewsAtSameSales() {
        var ranked=FeaturedProductService.rank(new FeaturedProductStore.Data(100,4,List.of(observation(1,20,20,1,5),observation(2,20,20,100,4.8))));
        assertEquals(2L,ranked.getFirst().productId());
    }
    @Test void ratingCanChangeRankBetweenSimilarlyPopularProductsAndTiesAreStable() {
        var ranked=FeaturedProductService.rank(new FeaturedProductStore.Data(100,4,List.of(observation(1,25,25,100,2),observation(2,24,24,100,5))));
        assertEquals(2L,ranked.getFirst().productId());
        ranked=FeaturedProductService.rank(new FeaturedProductStore.Data(100,4,List.of(observation(3,20,30,0,0),observation(2,20,30,0,0),observation(1,20,40,0,0))));
        assertEquals(List.of(1L,2L,3L),ranked.stream().map(FeaturedProductService.Score::productId).toList());
        assertEquals(4,ranked.getFirst().adjustedRating());
        assertTrue(FeaturedProductService.rank(new FeaturedProductStore.Data(0,3,List.of())).isEmpty());
    }
    @Test void statsCacheLastsFifteenMinutesButEligibilityAndCardsAreRefreshedEachRequest() {
        var now=Instant.parse("2026-10-16T00:00:00Z");var clock=mock(Clock.class);when(clock.instant()).thenReturn(now);
        var store=mock(FeaturedProductStore.class);var products=mock(ProductService.class);
        when(store.load(any(),any())).thenReturn(new FeaturedProductStore.Data(100,4,List.of(observation(1,25,30,10,5),observation(2,20,20,10,4))));
        when(products.featuredCards(anyList())).thenReturn(List.of(card(1),card(2)));
        var service=new FeaturedProductService(store,products,clock);
        assertEquals(1,service.get(1).products().size());
        when(products.featuredCards(anyList())).thenReturn(List.of(card(2)));
        assertEquals(2L,service.get(8).products().getFirst().product().id());
        verify(store,times(1)).load(now.minus(Duration.ofDays(30)),now);
        when(clock.instant()).thenReturn(now.plusSeconds(900));service.get(8);verify(store,times(2)).load(any(),any());
    }
    @Test void configuredWeightsActuallyChangeOrdering() {
        var data=new FeaturedProductStore.Data(100,4,List.of(observation(1,25,25,100,2),observation(2,24,24,100,5)));
        assertEquals(1L,FeaturedProductService.rank(data,100,0).getFirst().productId());
        assertEquals(2L,FeaturedProductService.rank(data,0,100).getFirst().productId());
    }

    @Test void bestSellersUseNetUnitsAndSkipProductsThatAreNoLongerAvailable() {
        var store = mock(FeaturedProductStore.class);
        var products = mock(ProductService.class);
        when(store.load(any(), any())).thenReturn(new FeaturedProductStore.Data(100, 4, List.of(
                observation(1, 20, 20, 100, 5),
                observation(2, 2, 30, 1, 2),
                observation(3, 20, 40, 5, 4))));
        when(products.featuredCards(anyList())).thenReturn(List.of(card(1), card(2)));
        var service = new FeaturedProductService(store, products, Clock.fixed(Instant.EPOCH, ZoneOffset.UTC));

        assertEquals(List.of(2L, 1L), service.bestSellers(2).stream().map(ProductCardResponse::id).toList());
        assertEquals(List.of(2L), service.bestSellers(1).stream().map(ProductCardResponse::id).toList());
    }
}
