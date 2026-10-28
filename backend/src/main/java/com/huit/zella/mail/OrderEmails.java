package com.huit.zella.mail;

import com.huit.zella.order.Order;
import com.huit.zella.order.OrderItem;
import com.huit.zella.order.OrderStatus;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.text.NumberFormat;
import java.util.Locale;

@Service @RequiredArgsConstructor
public class OrderEmails {
    private final EmailQueue queue;
    private final OrderEmailTemplate template;
    private final com.huit.zella.productimage.ProductImageRepository productImages;
    private final com.huit.zella.variantimage.VariantImageRepository variantImages;

    public void enqueue(Order order, boolean created) {
        String recipient = order.getRecipientEmail();
        if (recipient == null && order.getCustomer() != null) recipient = order.getCustomer().getEmail();
        if (!queue.enabled() || recipient == null || recipient.isBlank()) return;
        String status = switch (order.getStatus()) {
            case PENDING -> "Chờ thanh toán";
            case CONFIRMED -> "Đã xác nhận";
            case SHIPPED -> "Đang giao hàng";
            case DELIVERED -> "Đã giao hàng";
            case CANCELLED -> "Đã hủy";
            case RETURNED -> "Đã nhận lại hàng trả";
        };
        String payment = switch (order.getPaymentStatus()) {
            case "PAID" -> "Đã thanh toán";
            case "REFUND_PENDING" -> "Chờ hoàn tiền";
            case "REFUNDED" -> "Đã hoàn tiền";
            case "EXPIRED" -> "Hết hạn thanh toán";
            default -> "Chờ thanh toán";
        };
        NumberFormat money = NumberFormat.getCurrencyInstance(Locale.forLanguageTag("vi-VN"));
        StringBuilder body = new StringBuilder("Xin chào ").append(order.getRecipientName())
                .append(",\n\n").append(created ? "ZELLA đã nhận đơn hàng " : "Đơn hàng ")
                .append(order.getCode()).append(".\nTrạng thái: ").append(status)
                .append("\nThanh toán: ").append(payment).append("\n\nSản phẩm:\n");
        for (OrderItem item : order.getItems()) {
            body.append("- ").append(item.getProductName()).append(" (").append(item.getSku())
                    .append(") x ").append(item.getQuantity()).append(": ")
                    .append(money.format(item.getUnitPrice().multiply(java.math.BigDecimal.valueOf(item.getQuantity())))).append('\n');
        }
        body.append("\nTiền sản phẩm: ").append(money.format(order.getSubtotal()))
                .append("\nPhí vận chuyển: ").append(money.format(order.getShippingFee()))
                .append("\nGiảm giá: ").append(money.format(order.getDiscountAmount()))
                .append("\nTổng thanh toán: ").append(money.format(order.getTotalAmount()))
                .append("\n\nNgười nhận: ").append(order.getRecipientName())
                .append("\nSố điện thoại: ").append(order.getRecipientPhone())
                .append("\nĐịa chỉ: ").append(order.getAddress());
        if (order.getStatus() == OrderStatus.PENDING) body.append("\n\nVui lòng hoàn tất thanh toán trong thời hạn hiển thị tại trang thanh toán để giữ hàng.");
        body.append("\n\nCảm ơn bạn đã mua sắm tại ZELLA.");
        queue.enqueueHtml(recipient, "ZELLA - " + (created ? "Đã nhận đơn " : status + " - ") + order.getCode(),
                body.toString(), template.render(order, created, status, payment, images(order)), null);
    }

    private java.util.Map<OrderItem, String> images(Order order) {
        var productIds = order.getItems().stream().filter(item -> item.getProduct() != null)
                .map(item -> item.getProduct().getId()).filter(java.util.Objects::nonNull).distinct().toList();
        var variantIds = order.getItems().stream().filter(item -> item.getVariant() != null)
                .map(item -> item.getVariant().getId()).filter(java.util.Objects::nonNull).distinct().toList();
        java.util.Map<Long, String> byProduct = new java.util.HashMap<>(), byVariant = new java.util.HashMap<>();
        if (!productIds.isEmpty()) for (var image : productImages.findByProductIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(productIds))
            byProduct.putIfAbsent(image.getProduct().getId(), image.getImageUrl());
        if (!variantIds.isEmpty()) for (var image : variantImages.findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(variantIds))
            byVariant.putIfAbsent(image.getVariant().getId(), image.getImageUrl());
        java.util.Map<OrderItem, String> result = new java.util.HashMap<>();
        for (var item : order.getItems()) {
            String image = item.getVariant() == null ? null : byVariant.get(item.getVariant().getId());
            if (image == null && item.getProduct() != null) image = byProduct.get(item.getProduct().getId());
            if (image != null) result.put(item, image);
        }
        return result;
    }
}
