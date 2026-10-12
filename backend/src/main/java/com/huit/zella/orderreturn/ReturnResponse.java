package com.huit.zella.orderreturn;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;

public record ReturnResponse(Long id, Long orderId, String orderCode, String code, String status,
    String reason, String adminNote, BigDecimal refundAmount, String refundMethod, OffsetDateTime createdAt,
    List<Item> items, List<History> histories) {
    public record Item(Long id, Long orderItemId, Long variantId, String productName, String sku,
        int quantity, String condition) {}
    public record History(String oldStatus, String newStatus, String note, String changedBy, OffsetDateTime createdAt) {}
    public static ReturnResponse from(ReturnRequest r) {
        return new ReturnResponse(r.getId(), r.getOrder().getId(), r.getOrder().getCode(), r.getCode(),
            r.getStatus().name(), r.getNote(), r.getAdminNote(), r.getRefundAmount(), r.getRefundMethod(), r.getCreatedAt().atOffset(ZoneOffset.UTC),
            r.getItems().stream().map(i -> new Item(i.getId(), i.getOrderItem().getId(),
                i.getOrderItem().getVariant().getId(), i.getOrderItem().getProductName(), i.getOrderItem().getSku(),
                i.getQuantity(), i.getItemCondition())).toList(),
            r.getHistories().stream().map(h -> new History(h.getOldStatus(), h.getNewStatus(), h.getNote(),
                h.getChangedBy().getUserName(), h.getCreatedAt().atOffset(ZoneOffset.UTC))).toList());
    }
}
