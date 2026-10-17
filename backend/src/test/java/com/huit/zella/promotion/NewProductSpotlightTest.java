package com.huit.zella.promotion;
import com.huit.zella.product.*;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.*;
import java.time.*;
import java.math.BigDecimal;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class NewProductSpotlightTest {
    final Instant now=Instant.parse("2026-10-16T00:00:00Z");
    final PromotionRepository promotions=mock(PromotionRepository.class);
    final ProductService products=mock(ProductService.class);
    final AutomaticNewProductShowcaseService automatic=mock(AutomaticNewProductShowcaseService.class);
    final NewProductSpotlightService service=new NewProductSpotlightService(promotions,Clock.fixed(now,ZoneOffset.UTC),products,automatic);
    Promotion campaign(long id) {
        var c=new Promotion();c.setId(id);c.setName("Campaign "+id);c.setTargetMode("SELECTED");
        c.setDiscountPercent(BigDecimal.TEN);c.setDisplay(true);c.setActive(true);c.setImageUrl("https://cloud.example/campaign.jpg");
        c.setStartsAt(now.minusSeconds(60));c.setEndsAt(now.plusSeconds(3600));
        var p=new Product();p.setId(id);c.getProducts().add(p);return c;
    }
    @Test void legacyNewProgramNeverAppearsAsManagedCampaign() {
        var c=campaign(1);c.setTargetMode("NEW_PRODUCTS");
        when(promotions.effective(now)).thenReturn(List.of(c));
        assertTrue(service.list().isEmpty());verifyNoInteractions(products);verify(automatic).get();
    }
    @Test void everySelectedProgramHasItsOwnProducts() {
        var card=new ProductCardResponse(7L,"Product","product",BigDecimal.TEN,null,null,"https://cloud.example/p.jpg",List.of(),null,null,0L);
        when(promotions.effective(now)).thenReturn(List.of(campaign(1),campaign(2)));
        when(products.listSelectedCampaignProducts(anyList(),any())).thenReturn(new PageImpl<>(List.of(card)));
        assertEquals(List.of(1L,2L),service.list().stream().map(NewProductSpotlightService.Spotlight::id).toList());
        verify(products).listSelectedCampaignProducts(eq(List.of(1L)),any());
        verify(products).listSelectedCampaignProducts(eq(List.of(2L)),any());
    }
    @Test void emptySelectedDoesNotHideAutomaticShowcase() {
        var automaticBlock=new NewProductSpotlightService.Spotlight("New","New",null,"image",null,null,List.of(),-1L,"NEW_PRODUCTS");
        when(automatic.get()).thenReturn(automaticBlock);
        when(promotions.effective(now)).thenReturn(List.of(campaign(1)));
        when(products.listSelectedCampaignProducts(anyList(),any())).thenReturn(Page.empty());
        assertEquals(List.of(automaticBlock),service.list());assertSame(automaticBlock,service.get());
    }
    @Test void disabledHiddenExpiredFutureMissingCoverNeverExposeSelectedProgram() {
        var disabled=campaign(1);disabled.setActive(false);
        var hidden=campaign(2);hidden.setDisplay(false);
        var expired=campaign(3);expired.setEndsAt(now);
        var future=campaign(4);future.setStartsAt(now.plusSeconds(1));
        var missing=campaign(5);missing.setImageUrl(null);
        when(promotions.effective(now)).thenReturn(List.of(disabled,hidden,expired,future,missing));
        assertTrue(service.list().isEmpty());verifyNoInteractions(products);
    }
}
