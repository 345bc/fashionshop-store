package com.huit.zella.order;

import com.huit.zella.customer.CustomerRepository;
import java.math.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor
public class CheckoutPricingService {
    private final CheckoutPricingProperties policy;
    private final CustomerRepository customers;

    @Transactional(readOnly=true)
    public void prepare(Order order,Long userId,String method) {
        BigDecimal base=nonnegative(policy.getStandardShippingFee());
        BigDecimal shippingDiscount=order.getSubtotal().compareTo(nonnegative(policy.getShippingDiscountThreshold()))>=0
                ? nonnegative(policy.getShippingDiscountAmount()).min(base):BigDecimal.ZERO;
        String tier=userId==null?"STANDARD":customers.findByUserId(userId).map(customer -> customer.getMembershipTier()).orElse("STANDARD");
        BigDecimal percent = BigDecimal.ZERO;
        if (userId != null) {
            if ("PLATINUM".equals(tier)) percent = new BigDecimal("10");
            else if ("GOLD".equals(tier)) percent = new BigDecimal("7");
            else if ("SILVER".equals(tier)) percent = new BigDecimal("5");
        }
        BigDecimal member=order.getSubtotal().multiply(percent).divide(new BigDecimal("100"),0,RoundingMode.DOWN);
        order.setShippingDiscountAmount(shippingDiscount);order.setShippingFee(base.subtract(shippingDiscount));
        order.setMembershipDiscountPercent(percent);order.setMembershipDiscountAmount(member);
        order.setDiscountAmount(member);order.setTotalAmount(order.getSubtotal().add(order.getShippingFee()).subtract(member));
    }
    public CheckoutPriceResponse snapshot(Order order) {
        return new CheckoutPriceResponse(order.getSubtotal(),order.getShippingFee().add(order.getShippingDiscountAmount()),
                order.getShippingDiscountAmount(),order.getShippingFee(),order.getMembershipDiscountPercent(),order.getMembershipDiscountAmount(),
                order.getDiscountAmount().subtract(order.getMembershipDiscountAmount()),order.getDiscountAmount(),order.getTotalAmount(),
                nonnegative(policy.getShippingDiscountThreshold()),nonnegative(policy.getShippingDiscountAmount()));
    }
    private BigDecimal nonnegative(BigDecimal value) { return value==null?BigDecimal.ZERO:value.max(BigDecimal.ZERO); }
}
