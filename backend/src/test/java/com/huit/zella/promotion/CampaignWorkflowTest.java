package com.huit.zella.promotion;
import com.huit.zella.inventory.WarehouseFixture;
import com.huit.zella.order.*;
import com.huit.zella.cart.*;
import com.huit.zella.voucher.*;
import com.huit.zella.loyalty.LoyaltyService;
import com.huit.zella.common.exception.BusinessException;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(properties="app.order.expiration.enabled=false") @Transactional
class CampaignWorkflowTest extends WarehouseFixture {
    @Autowired CampaignManagementService campaigns;
    @Autowired PromotionPricingService pricing;
    @Autowired OrderService orders;
    @Autowired CartService carts;
    @Autowired LoyaltyService loyalty;
    @Autowired VoucherService vouchers;
    @Autowired Clock clock;
    @Autowired org.springframework.web.context.WebApplicationContext context;

    CampaignRequest promotion(String mode,int percent,List<Long> ids) {
        return new CampaignRequest("Ưu đãi test","Test",clock.instant().minusSeconds(60),clock.instant().plusSeconds(3600),true,
            null,null,null,null,null,null,new BigDecimal(percent),mode,ids,false,null);
    }
    CampaignRequest voucher(boolean reward,int points,int quota) {
        return new CampaignRequest("Voucher test","Ưu đãi test",clock.instant().minusSeconds(60),clock.instant().plusSeconds(3600),true,
            "TEST-"+UUID.randomUUID().toString().substring(0,8).toUpperCase(),"FIXED",new BigDecimal("20"),BigDecimal.ZERO,null,quota,null,null,List.of(),reward,points);
    }
    @Test void newProductsExpireAndBestOfferWinsWithoutChangingStoredPrices() {
        var p=variant.getProduct();
        campaigns.save("promotion",null,promotion("NEW_PRODUCTS",5,List.of()));
        assertEquals(0,pricing.price(p,new BigDecimal("300"),pricing.offers(List.of(p))).compareTo(new BigDecimal("285")));
        var second=campaigns.save("promotion",null,promotion("SELECTED",10,List.of(p.getId())));
        assertEquals(0,pricing.price(p,new BigDecimal("300"),pricing.offers(List.of(p))).compareTo(new BigDecimal("270")));
        campaigns.state("promotion",second.id(),false);
        p.setCreatedAt(clock.instant().minus(Duration.ofDays(8)));em.flush();
        assertTrue(pricing.offers(List.of(p)).isEmpty());
        assertEquals(0,variant.getPrice().compareTo(new BigDecimal("300")));
    }
    @Test void cartQuoteAndOrderUseSamePriceAndOrderKeepsSnapshot() {
        var promotion=campaigns.save("promotion",null,promotion("SELECTED",5,List.of(variant.getProduct().getId())));
        var quote=carts.quote(List.of(new CartItemRequest(variant.getId(),2)));
        var order=orders.create(new CreateOrderRequest(actor.getId(),"Test","0900000000","Test",null,BigDecimal.ZERO,"ONLINE",
            List.of(new CreateOrderRequest.Item(variant.getId(),2))),actor.getId());
        assertEquals(0,quote.subtotal().compareTo(order.subtotal()));
        assertEquals(0,order.subtotal().compareTo(new BigDecimal("570")));
        campaigns.state("promotion",promotion.id(),false);
        var saved=em.find(Order.class,order.id());
        assertEquals(0,saved.getSubtotal().compareTo(new BigDecimal("570")));
        assertEquals(0,saved.getOriginalSubtotal().compareTo(new BigDecimal("600")));
        assertEquals(0,carts.quote(List.of(new CartItemRequest(variant.getId(),2))).subtotal().compareTo(new BigDecimal("600")));
    }
    @Test void rewardManagementRedeemsExactlyOnceAndEnforcesQuotaAndOwnership() {
        var request=voucher(true,100,1);
        var template=campaigns.save("voucher",null,request);
        assertTrue(campaigns.list("voucher").stream().anyMatch(v->v.id().equals(template.id()) && v.redeemable()));
        actor.getCustomer().setRewardPoints(250);em.flush();
        String key=UUID.randomUUID().toString();
        var issued=loyalty.redeem(actor.getId(),template.id(),key);
        assertEquals(150,actor.getCustomer().getRewardPoints());
        assertEquals(issued.id(),loyalty.redeem(actor.getId(),template.id(),key).id());
        assertEquals(150,actor.getCustomer().getRewardPoints());
        assertEquals(1,campaigns.detail("voucher",template.id()).usedCount());
        assertEquals(issued.code(),campaigns.detail("voucher",template.id()).usages().getFirst().orderCode());
        assertEquals(100,campaigns.detail("voucher",template.id()).usages().getFirst().pointsRequired());
        assertThrows(BusinessException.class,()->loyalty.redeem(actor.getId(),template.id(),UUID.randomUUID().toString()));
        assertThrows(BusinessException.class,()->campaigns.detail("voucher",issued.id()));
        var changed = new CampaignRequest(request.name(),request.description(),request.startsAt(),request.endsAt(),true,
            request.code(),"FIXED",new BigDecimal("50"),BigDecimal.ZERO,null,1,null,null,List.of(),true,100);
        campaigns.save("voucher",template.id(),changed);
        Order order=new Order();order.setSubtotal(new BigDecimal("300"));order.setTotalAmount(new BigDecimal("300"));
        vouchers.apply(order,actor.getId(),issued.code());
        assertEquals(0,order.getTotalAmount().compareTo(new BigDecimal("280")));
    }
    @Test void campaignApisRequireStaffRole() throws Exception {
        var mvc=org.springframework.test.web.servlet.setup.MockMvcBuilders.webAppContextSetup(context)
            .apply(org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity()).build();
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/v1/campaigns/voucher"))
            .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isUnauthorized());
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/v1/campaigns/voucher")
            .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user("customer").roles("CUSTOMER")))
            .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isForbidden());
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get("/api/v1/campaigns/voucher")
            .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user("admin").roles("ADMIN")))
            .andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isOk());
    }
    @Test void pausedRewardCannotBeRedeemedAndPersonalVoucherIsNotAnAdminTemplate() {
        var template=campaigns.save("voucher",null,voucher(true,100,5));
        campaigns.state("voucher",template.id(),false);
        actor.getCustomer().setRewardPoints(200);em.flush();
        assertThrows(BusinessException.class,()->loyalty.redeem(actor.getId(),template.id(),UUID.randomUUID().toString()));
        assertEquals(200,actor.getCustomer().getRewardPoints());
        assertThrows(BusinessException.class,()->campaigns.save("promotion",null,promotion("SELECTED",5,List.of())));
    }
}
