package com.huit.zella.promotion;
import com.huit.zella.product.*;
import com.huit.zella.category.Category;
import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.data.domain.*;
import java.time.*;
import java.math.BigDecimal;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class AutomaticNewProductTest {
    final Instant now=Instant.parse("2026-10-16T00:00:00Z");
    final Clock clock=Clock.fixed(now,ZoneOffset.UTC);
    final PromotionRepository repository=mock(PromotionRepository.class);
    Product product(Instant created) {
        var p=new Product();p.setId(1L);p.setCreatedAt(created);
        var c=new Category();c.setIsActive(true);p.setCategory(c);return p;
    }
    @Test void automaticDiscountNeedsNoManagedProgramAndExpiresAtSevenDays() {
        var pricing=new PromotionPricingService(repository,clock);
        for(var created:List.of(now,now.minusSeconds(604799))) {
            var p=product(created);var offers=pricing.offers(List.of(p));
            assertEquals(new BigDecimal("5"),offers.get(1L).percent());
            assertEquals(new BigDecimal("95000"),pricing.price(p,new BigDecimal("100000"),offers));
        }
        for(var created:List.of(now.minusSeconds(604800),now.plusSeconds(1)))
            assertTrue(pricing.offers(List.of(product(created))).isEmpty());
        var hidden=product(now);hidden.setActive(false);assertTrue(pricing.offers(List.of(hidden)).isEmpty());
    }
    @Test void selectedOfferOnlyOverridesAutomaticWhenHigherAndNeverStacks() {
        var p=product(now);var c=new Promotion();c.setId(2L);c.setTargetMode("SELECTED");c.getProducts().add(p);
        c.setDiscountPercent(BigDecimal.TEN);when(repository.effective(now)).thenReturn(List.of(c));
        var pricing=new PromotionPricingService(repository,clock);
        assertEquals(new BigDecimal("90000"),pricing.price(p,new BigDecimal("100000"),pricing.offers(List.of(p))));
        c.setDiscountPercent(new BigDecimal("3"));assertEquals(new BigDecimal("5"),pricing.offers(List.of(p)).get(1L).percent());
        c.setTargetMode("NEW_PRODUCTS");c.setDiscountPercent(new BigDecimal("99"));
        assertEquals(new BigDecimal("5"),pricing.offers(List.of(p)).get(1L).percent());
    }
    @Test void automaticProgramsAreHiddenAndCannotBeEditedOrToggledThroughManagement() {
        var legacy=new Promotion();legacy.setId(1L);legacy.setTargetMode("NEW_PRODUCTS");
        when(repository.findAllByOrderByIdDesc()).thenReturn(List.of(legacy));
        when(repository.findById(1L)).thenReturn(Optional.of(legacy));when(repository.lock(1L)).thenReturn(Optional.of(legacy));
        var service=new CampaignManagementService(mock(com.huit.zella.voucher.VoucherRepository.class),repository,
            mock(ProductRepository.class),mock(com.huit.zella.order.OrderRepository.class),clock);
        assertTrue(service.list("promotion").isEmpty());
        assertThrows(BusinessException.class,()->service.detail("promotion",1L));
        assertThrows(BusinessException.class,()->service.state("promotion",1L,false));
        var request=new CampaignRequest("New",null,now,now.plusSeconds(60),true,null,null,null,null,null,null,BigDecimal.TEN,"NEW_PRODUCTS",List.of(),false,null);
        assertThrows(BusinessException.class,()->service.save("promotion",null,request));
    }
    @Test @SuppressWarnings("unchecked") void showcaseUsesSeparateAssetsAndHidesWhenNoEligibleProducts() {
        var jdbc=mock(JdbcTemplate.class);var products=mock(ProductService.class);
        when(jdbc.query(anyString(),any(RowMapper.class))).thenReturn(Collections.singletonList(new String[]{"Auto","Description","https://image.example/a.jpg"}));
        when(products.listNewArrivalsAt(eq(now),any())).thenReturn(Page.empty());
        var service=new AutomaticNewProductShowcaseService(jdbc,products,clock);assertNull(service.get());
        var card=new ProductCardResponse(1L,"New product","new",BigDecimal.TEN,null,null,"image",List.of(),null,null,0L);
        when(products.listNewArrivalsAt(eq(now),any())).thenReturn(new PageImpl<>(List.of(card)));
        var result=service.get();assertEquals(-1L,result.id());assertEquals("Auto",result.title());assertEquals(List.of(card),result.products());
    }
}
