package com.huit.zella.order;

import java.math.BigDecimal;

public record CheckoutPriceResponse(BigDecimal subtotal, BigDecimal shippingBaseFee,
        BigDecimal shippingDiscountAmount, BigDecimal shippingFee,
        BigDecimal membershipDiscountPercent, BigDecimal membershipDiscountAmount,
        BigDecimal couponDiscountAmount, BigDecimal discountAmount, BigDecimal totalAmount,
        BigDecimal shippingDiscountThreshold, BigDecimal shippingPromotionAmount) {}
