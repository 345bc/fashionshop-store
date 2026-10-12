package com.huit.zella.account;

import com.huit.zella.inventory.WarehouseFixture;
import com.huit.zella.loyalty.LoyaltyService;
import com.huit.zella.order.*;
import com.huit.zella.orderreturn.*;
import com.huit.zella.cart.*;
import com.huit.zella.product.ProductService;
import com.huit.zella.voucher.*;
import java.math.BigDecimal;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.transaction.annotation.Transactional;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(properties="app.order.expiration.enabled=false") @Transactional
class CustomerAccountWorkflowTest extends WarehouseFixture {
    @Autowired OrderService orders;
    @Autowired CustomerOrderService account;
    @Autowired LoyaltyService loyalty;
    @Autowired ProductService products;
    @Autowired VoucherRepository vouchers;
    @Autowired VoucherService voucherService;
    @Autowired CartService cart;
    @Autowired ReturnService returns;

    @Test void deliveryReviewRedemptionAndCheckoutUseRealOwnedData() {
        variant.setPrice(new BigDecimal("500000")); actor.getCustomer().setRewardPoints(200);
        OrderResponse order=orders.create(new CreateOrderRequest(actor.getId(),"Test","0900000000","Test",null,BigDecimal.ZERO,"ONLINE",
                List.of(new CreateOrderRequest.Item(variant.getId(),1))),actor.getId());
        orders.recordOnlinePayment(order.id(),order.totalAmount(),UUID.randomUUID().toString());orders.ship(order.id(),actor.getId());orders.deliver(order.id(),actor.getId());
        assertEquals(250,loyalty.summary(actor.getId()).balance());
        assertEquals(1,account.list(actor.getId(),"ALL",true,PageRequest.of(0,10)).getTotalElements());
        account.review(order.id(),order.items().getFirst().id(),actor.getId(),new CustomerOrderService.ReviewRequest(4,"Đúng mô tả"));
        var publicReviews=products.listReviews(variant.getProduct().getId(),PageRequest.of(0,20));assertEquals(1,publicReviews.getTotalElements());assertEquals(4,publicReviews.getContent().getFirst().rating());
        var offer=loyalty.summary(actor.getId()).rewards().stream().filter(item -> item.code().equals("REWARD-20")).findFirst().orElseThrow(() -> new IllegalStateException(
                "Missing catalog offer; UTC="+java.time.LocalDateTime.now(java.time.ZoneOffset.UTC)+"; templates="+vouchers.findAll().stream().filter(v -> v.isRedeemable()).map(v -> v.getCode()+":"+v.getStartDate()+":"+v.getEndDate()+":"+v.isActive()).toList()));
        String key=UUID.randomUUID().toString();var issued=loyalty.redeem(actor.getId(),offer.id(),key);
        loyalty.redeem(actor.getId(),offer.id(),key);assertEquals(50,loyalty.summary(actor.getId()).balance());
        var quoted=voucherService.quote(List.of(new CartItemRequest(variant.getId(),1)),actor.getId(),issued.code(),cart);
        assertEquals(0,new BigDecimal("455000").compareTo(quoted.totalAmount()));
        var checkout=orders.createCheckout(new CreateCheckoutOrderRequest("Test","0900000000","Test",null,"STANDARD",List.of(new CreateOrderRequest.Item(variant.getId(),1)),UUID.randomUUID().toString(),issued.code()),actor.getId());
        assertEquals(0,quoted.totalAmount().compareTo(checkout.totalAmount()));assertEquals(0,new BigDecimal("45000").compareTo(checkout.discountAmount()));
        assertEquals(0,new BigDecimal("25000").compareTo(checkout.pricing().membershipDiscountAmount()));
        assertEquals(0,new BigDecimal("20000").compareTo(checkout.pricing().couponDiscountAmount()));
        orders.cancel(checkout.id(),"Test",actor.getId());
        assertFalse(loyalty.summary(actor.getId()).vouchers().content().getFirst().used());
    }
    @Test void returnKeepsZeroBalanceAndShowsAdjustmentThenNextDeliveryOffsetsIt() {
        variant.setPrice(new BigDecimal("500000"));
        OrderResponse order=delivered();assertEquals(50,loyalty.summary(actor.getId()).balance());
        // Simulate points already spent; redemption mechanics are exercised in the other workflow test.
        actor.getCustomer().setRewardPoints(20);
        var document=account.requestReturn(order.id(),actor.getId(),new CreateReturnRequest(order.id(),"Test",List.of(new CreateReturnRequest.Item(order.items().getFirst().id(),1))));
        returns.approve(document.id(),actor.getId());returns.receive(document.id(),new ReceiveReturnRequest(List.of(new ReceiveReturnRequest.Item(document.items().getFirst().id(),"INTACT"))),actor.getId());
        assertEquals(0,loyalty.summary(actor.getId()).balance());assertEquals(30,loyalty.summary(actor.getId()).adjustmentPoints());
        assertEquals("RETURNED",orders.get(order.id()).status());assertEquals("REFUND_PENDING",orders.get(order.id()).paymentStatus());
        delivered();assertEquals(20,loyalty.summary(actor.getId()).balance());assertEquals(0,loyalty.summary(actor.getId()).adjustmentPoints());
    }
    private OrderResponse delivered() {
        var order=orders.create(new CreateOrderRequest(actor.getId(),"Test","0900000000","Test",null,BigDecimal.ZERO,"ONLINE",List.of(new CreateOrderRequest.Item(variant.getId(),1))),actor.getId());
        orders.recordOnlinePayment(order.id(),order.totalAmount(),UUID.randomUUID().toString());orders.ship(order.id(),actor.getId());orders.deliver(order.id(),actor.getId());return orders.get(order.id());
    }
}
