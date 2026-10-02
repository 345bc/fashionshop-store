package com.huit.zella.order;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public record CheckoutOrderResponse(Long id, String code, String status, String paymentStatus,
    BigDecimal totalAmount, OffsetDateTime paymentExpiresAt, String checkoutToken) {}

