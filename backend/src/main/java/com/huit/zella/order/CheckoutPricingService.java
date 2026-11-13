package com.huit.zella.order;

import com.huit.zella.customer.CustomerRepository;
import com.huit.zella.customer.MembershipTier;

import java.math.*;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CheckoutPricingService {
    CheckoutPricingProperties policy;
    CustomerRepository customers;

    @Transactional(readOnly = true)
    public void prepare(Order order, Long userId, String method) {
        BigDecimal base = nonnegative(policy.getStandardShippingFee());
        BigDecimal shippingDiscount = order.getSubtotal().compareTo(nonnegative(policy.getShippingDiscountThreshold())) >= 0
                ? nonnegative(policy.getShippingDiscountAmount()).min(base) : BigDecimal.ZERO;
        MembershipTier tier = userId == null ? MembershipTier.STANDARD : customers.findByUserId(userId)
                .map(customer -> MembershipTier.fromStoredValue(customer.getMembershipTier()))
                .orElse(MembershipTier.STANDARD);
        BigDecimal percent = BigDecimal.valueOf(tier.getDiscountPercent());

        BigDecimal member = order.getSubtotal().multiply(percent).divide(new BigDecimal("100"), 0, RoundingMode.DOWN);
        order.setShippingDiscountAmount(shippingDiscount);
        order.setShippingFee(base.subtract(shippingDiscount));
        order.setMembershipDiscountPercent(percent);
        order.setMembershipDiscountAmount(member);
        order.setDiscountAmount(member);
        order.setTotalAmount(order.getSubtotal().add(order.getShippingFee()).subtract(member));
    }

    public CheckoutPriceResponse snapshot(Order order) {
        return new CheckoutPriceResponse(order.getSubtotal(), order.getShippingFee().add(order.getShippingDiscountAmount()),
                order.getShippingDiscountAmount(), order.getShippingFee(), order.getMembershipDiscountPercent(), order.getMembershipDiscountAmount(),
                order.getDiscountAmount().subtract(order.getMembershipDiscountAmount()), order.getDiscountAmount(), order.getTotalAmount(),
                nonnegative(policy.getShippingDiscountThreshold()), nonnegative(policy.getShippingDiscountAmount()));
    }

    private BigDecimal nonnegative(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value.max(BigDecimal.ZERO);
    }
}
