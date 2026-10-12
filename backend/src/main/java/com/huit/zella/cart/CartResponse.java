package com.huit.zella.cart;

import java.math.BigDecimal;
import java.util.List;

public record CartResponse(List<Item> items, int totalQuantity, BigDecimal subtotal) {
    public record Item(Long variantId, Long productId, String name, String slug, String sku,
                       String colorName, String sizeName, String imageUrl, int quantity,
                       int availableQuantity, BigDecimal unitPrice, BigDecimal lineTotal,
                       boolean purchasable, String unavailableReason) {}
}
