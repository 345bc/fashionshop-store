package com.huit.zella.order;

import com.huit.zella.customer.*;
import java.math.BigDecimal;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CheckoutPricingServiceTest {
    private final CheckoutPricingProperties policy=new CheckoutPricingProperties();
    private final CustomerRepository customers=mock(CustomerRepository.class);
    private final CheckoutPricingService pricing=new CheckoutPricingService(policy,customers);
    private Order order(String subtotal) { Order order=new Order();order.setSubtotal(new BigDecimal(subtotal));return order; }
    @Test void tiersUseApprovedPercentagesAndGuestsHaveNoMembershipDiscount() {
        Customer customer=new Customer();when(customers.findByUserId(1L)).thenReturn(Optional.of(customer));
        for(var rate:java.util.Map.of("STANDARD",5,"SILVER",7,"GOLD",10).entrySet()) {
            customer.setMembershipTier(rate.getKey());Order order=order("500000");pricing.prepare(order,1L,"STANDARD");
            assertEquals(0,BigDecimal.valueOf(rate.getValue()).compareTo(order.getMembershipDiscountPercent()));
            assertEquals(0,BigDecimal.valueOf(5000L*rate.getValue()).compareTo(order.getMembershipDiscountAmount()));
        }
        Order guest=order("500000");pricing.prepare(guest,null,"STANDARD");assertEquals(BigDecimal.ZERO,guest.getMembershipDiscountAmount());
    }
    @Test void shippingComesFromBackendPolicyAndThresholdUsesSubtotalBeforeDiscount() {
        policy.setStandardShippingFee(new BigDecimal("35000"));policy.setShippingDiscountAmount(new BigDecimal("20000"));
        Order below=order("599999");pricing.prepare(below,null,"STANDARD");assertEquals(0,new BigDecimal("35000").compareTo(below.getShippingFee()));
        Order eligible=order("600000");pricing.prepare(eligible,null,"STANDARD");assertEquals(0,new BigDecimal("15000").compareTo(eligible.getShippingFee()));
        assertEquals(0,new BigDecimal("35000").compareTo(pricing.snapshot(eligible).shippingBaseFee()));
    }
    @Test void defaultShippingStaysZeroAndPersistedAmountsSurvivePolicyChanges() {
        Customer customer=new Customer();when(customers.findByUserId(1L)).thenReturn(Optional.of(customer));
        Order order=order("519000");pricing.prepare(order,1L,"STANDARD");assertEquals(BigDecimal.ZERO,order.getShippingFee());
        assertEquals(0,new BigDecimal("25950").compareTo(order.getDiscountAmount()));
        policy.setStandardDiscountPercent(new BigDecimal("20"));assertEquals(0,new BigDecimal("5").compareTo(pricing.snapshot(order).membershipDiscountPercent()));
    }
}
