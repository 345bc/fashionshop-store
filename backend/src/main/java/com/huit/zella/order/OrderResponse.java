package com.huit.zella.order;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

public record OrderResponse(Long id, String code, Long customerUserId, String customerName,
    String recipientName, String recipientPhone, String address, String note,
    String status, String paymentStatus, String paymentMethod, boolean inventoryManaged,
    BigDecimal subtotal, BigDecimal shippingFee, BigDecimal totalAmount, OffsetDateTime createdAt,
    List<Item> items, List<History> histories, OffsetDateTime paymentExpiresAt) {
    public record Item(Long id, Long variantId, String productName, String sku, int quantity,
        BigDecimal unitPrice, BigDecimal subtotal, int returnedQuantity) {}
    public record History(String oldStatus, String newStatus, String note, String createdBy, OffsetDateTime createdAt) {}
}
