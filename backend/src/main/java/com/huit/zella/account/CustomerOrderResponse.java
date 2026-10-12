package com.huit.zella.account;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

public record CustomerOrderResponse(Long id, String code, String status, String paymentStatus,
        OffsetDateTime createdAt, BigDecimal subtotal, BigDecimal shippingFee, BigDecimal discountAmount,
        BigDecimal totalAmount, String recipientName, String recipientPhone, String address,
        List<Item> items, List<History> history) {
    public record Review(Long id, int rating, String comment, boolean hidden) {}
    public record Item(Long id, Long variantId, String name, String sku, String slug, String imageUrl,
            String colorName, String sizeName, int quantity, BigDecimal unitPrice, int returnedQuantity,
            boolean canReview, Review review) {}
    public record History(String status, String note, OffsetDateTime createdAt) {}
}
