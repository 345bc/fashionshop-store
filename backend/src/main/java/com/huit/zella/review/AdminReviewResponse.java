package com.huit.zella.review;

import java.time.Instant;
import java.util.List;

public record AdminReviewResponse(
        Long id, Long productId, Long orderId, Long orderItemId, Long customerId,
        int rating, String customerName, String customerEmail, String productName,
        String sku, String orderCode, String comment, Instant createdAt,
        boolean hidden, String adminReply, Instant repliedAt, String moderationReason,
        Long parentId, String parent, Long categoryId, String category, List<History> history) {
    public record History(String action, String actor, String note, Instant createdAt) {}

    static AdminReviewResponse from(ProductReview r) {
        var p = r.getProduct();
        var c = p.getCategory();
        var parent = c.getParent() == null ? c : c.getParent();
        var customer = r.getCustomer();
        var order = r.getOrder();
        var item = r.getOrderItem();
        return new AdminReviewResponse(r.getId(), p.getId(), order.getId(), item.getId(),
                customer == null ? null : customer.getId(), r.getRating(),
                customer == null ? order.getRecipientName() : customer.getFullName(),
                customer == null || customer.getUser() == null ? "" : customer.getUser().getEmail(),
                p.getName(), item.getSku(), order.getCode(), r.getComment(), r.getCreatedAt(),
                r.isHidden(), r.getAdminReply(), r.getRepliedAt(), r.getModerationReason(),
                parent.getId(), parent.getName(), c.getId(), c.getName(),
                r.getHistory().stream().map(h -> new History(h.getAction(), h.getActor(), h.getNote(), h.getCreatedAt())).toList());
    }
}
