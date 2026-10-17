package com.huit.zella.promotion;

import com.huit.zella.product.ProductRepository;
import com.huit.zella.voucher.VoucherRepository;
import com.huit.zella.order.OrderRepository;
import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;

class CampaignBannerTest {
    final Instant now=Instant.parse("2026-10-16T00:00:00Z");
    final PromotionRepository promotions=mock(PromotionRepository.class);
    final ProductRepository products=mock(ProductRepository.class);
    final CampaignManagementService service=new CampaignManagementService(mock(VoucherRepository.class),promotions,products,
            mock(OrderRepository.class),Clock.fixed(now,ZoneOffset.UTC));
    CampaignRequest request(String image,Boolean display) {
        return new CampaignRequest("Ưu đãi","Mô tả",now.minusSeconds(60),now.plusSeconds(3600),true,
                null,null,null,null,null,null,new BigDecimal("5"),"SELECTED",List.of(7L),false,null,image,display);
    }
    com.huit.zella.product.Product product() {
        var p=new com.huit.zella.product.Product();p.setId(7L);
        var c=new com.huit.zella.category.Category();c.setIsActive(true);p.setCategory(c);return p;
    }
    @Test void imageAndDisplayRoundTripAndRemainUnchangedForOlderClients() {
        when(products.findAllById(any())).thenReturn(List.of(product()));
        when(promotions.saveAndFlush(any())).thenAnswer(i->i.getArgument(0));
        var response=service.save("promotion",null,request("https://cloud.example/banner.jpg",true));
        assertTrue(response.isDisplay());assertEquals("https://cloud.example/banner.jpg",response.imageUrl());
        var existing=new Promotion();existing.setId(1L);existing.setDisplay(true);existing.setImageUrl(response.imageUrl());
        when(promotions.lock(1L)).thenReturn(Optional.of(existing));
        var updated=service.save("promotion",1L,request(null,null));
        assertTrue(updated.isDisplay());assertEquals(response.imageUrl(),updated.imageUrl());
    }
    @Test void displayingWithoutCoverIsRejectedAndHiddenCampaignCanStillBeActive() {
        assertThrows(BusinessException.class,()->service.save("promotion",null,request(null,true)));
        when(products.findAllById(any())).thenReturn(List.of(product()));
        when(promotions.saveAndFlush(any())).thenAnswer(i->i.getArgument(0));
        var response=service.save("promotion",null,request(null,false));
        assertTrue(response.enabled());assertFalse(response.isDisplay());
    }
}
