package com.huit.zella.order;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

public record CheckoutOrderResponse(Long id, String code, String status, String paymentStatus,
    BigDecimal totalAmount, OffsetDateTime paymentExpiresAt, String checkoutToken, List<Item> items,
    BigDecimal subtotal, BigDecimal shippingFee, BigDecimal discountAmount,CheckoutPriceResponse pricing) {
    public record Item(Long variantId, String name, String sku, int quantity, BigDecimal unitPrice, BigDecimal lineTotal) {}
}

