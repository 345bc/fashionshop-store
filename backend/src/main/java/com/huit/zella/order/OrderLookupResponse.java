package com.huit.zella.order;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

/** Public tracking view. Does not expose identity, address or checkout capabilities. */
public record OrderLookupResponse(String code, String status, String paymentStatus,
        OffsetDateTime createdAt, BigDecimal totalAmount, List<Item> items) {
    public record Item(String name, String sku, int quantity, BigDecimal lineTotal) {}
}
