package com.huit.zella.order;

import java.math.BigDecimal;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "app.checkout.pricing")
@Getter
@Setter
public class CheckoutPricingProperties {
    private BigDecimal standardShippingFee = new BigDecimal("30000.0");
    private BigDecimal shippingDiscountThreshold = new BigDecimal("600000");
    private BigDecimal shippingDiscountAmount = new BigDecimal("30000.0");
    private BigDecimal standardDiscountPercent = new BigDecimal("5");
    private BigDecimal silverDiscountPercent = new BigDecimal("7");
    private BigDecimal goldDiscountPercent = new BigDecimal("10");
}
