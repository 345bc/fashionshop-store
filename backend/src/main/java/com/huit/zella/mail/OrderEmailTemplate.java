package com.huit.zella.mail;

import com.huit.zella.order.Order;
import com.huit.zella.order.OrderStatus;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.text.NumberFormat;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.Pattern;

@Component
public class OrderEmailTemplate {
    private final String template;
    private final String trackingUrl;
    private final java.net.URI frontendUri;

    public OrderEmailTemplate(@Value("${app.frontend-url:http://localhost:3000}") String frontend) {
        var uri = java.net.URI.create(frontend);
        if (!Set.of("http", "https").contains(uri.getScheme()) || uri.getHost() == null || uri.getRawQuery() != null
                || uri.getRawFragment() != null || uri.getUserInfo() != null)
            throw new IllegalArgumentException("Invalid app.frontend-url");
        trackingUrl = frontend.replaceAll("/+$", "") + "/order-tracking";
        frontendUri = uri;
        try {
            template = new ClassPathResource("templates/email/order.html").getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException failure) {
            throw new IllegalStateException("Order email template is missing", failure);
        }
    }

    public String render(Order order, boolean created, String status, String payment) {
        return render(order, created, status, payment, Map.of());
    }

    public String render(Order order, boolean created, String status, String payment,
                         Map<com.huit.zella.order.OrderItem, String> images) {
        boolean cancelled = order.getStatus() == OrderStatus.CANCELLED;
        String title = created ? "Đã nhận đơn hàng của bạn." : switch (order.getStatus()) {
            case PENDING -> "Đơn hàng đang chờ thanh toán.";
            case CONFIRMED -> "Đơn hàng đã được xác nhận.";
            case SHIPPED -> "Đơn hàng đang trên đường đến bạn.";
            case DELIVERED -> "Đơn hàng đã giao thành công.";
            case CANCELLED -> "Đơn hàng đã được hủy.";
            case RETURNED -> "ZELLA đã nhận lại hàng trả.";
        };
        String description = created ? "ZELLA đã nhận đơn. Vui lòng hoàn tất thanh toán trong thời hạn hiển thị tại trang thanh toán."
                : switch (order.getStatus()) {
            case PENDING ->
                    "Vui lòng hoàn tất thanh toán trong thời hạn hiển thị ở trang thanh toán để giữ sản phẩm của bạn.";
            case CONFIRMED -> "Thanh toán đã được ghi nhận. ZELLA đang chuẩn bị đơn hàng của bạn.";
            case SHIPPED -> "Đơn hàng đã được bàn giao cho đơn vị vận chuyển. Vui lòng giữ liên lạc để nhận hàng.";
            case DELIVERED ->
                    "Đơn hàng đã được giao đến bạn. Cảm ơn bạn đã mua sắm tại ZELLA.";
            case CANCELLED ->
                    "Đơn hàng này đã dừng xử lý. Thông tin đơn và trạng thái thanh toán được ghi bên dưới.";
            case RETURNED ->
                    "Hàng trả đã được tiếp nhận. Thông tin thanh toán và hoàn tiền hiện tại được cập nhật bên dưới.";
        };
        Map<String, String> values = new HashMap<>();
        values.put("TITLE", escape(title));
        values.put("DESCRIPTION", escape(description));
        values.put("PREHEADER", escape(status + " · " + order.getCode() + " · Cập nhật đơn hàng ZELLA"));
        values.put("NAME", escape(order.getRecipientName()));
        values.put("CODE", escape(order.getCode()));
        values.put("STATUS", escape(status));
        values.put("PAYMENT", escape(payment));
        values.put("STATUS_COLOR", cancelled ? "#95564c" : "#555555");
        values.put("PHONE", escape(order.getRecipientPhone()));
        values.put("ADDRESS", escape(order.getAddress()));
        values.put("DATE", order.getCreatedAt() == null ? "" : DateTimeFormatter.ofPattern("dd.MM.yyyy · HH:mm")
                .withZone(ZoneId.of("Asia/Ho_Chi_Minh")).format(order.getCreatedAt().toInstant(ZoneOffset.UTC)));
        values.put("SUBTOTAL", money(order.getSubtotal()));
        values.put("SHIPPING", money(order.getShippingFee()));
        values.put("DISCOUNT", money(order.getDiscountAmount()));
        values.put("TOTAL", money(order.getTotalAmount()));
        values.put("TOTAL_LABEL", cancelled ? "Giá trị đơn hàng" : "Tổng thanh toán");
        values.put("TRACKING_URL", escape(trackingUrl));
        StringBuilder items = new StringBuilder();
        for (var item : order.getItems()) {
            items.append("<tr><td style=\"padding:20px 0;border-bottom:1px solid #e7e7e7;vertical-align:top\">")
                    .append("<table role=\"presentation\" width=\"100%\" cellspacing=\"0\" cellpadding=\"0\" style=\"table-layout:fixed\"><tr>");
            String image = safeImageUrl(images.get(item));
            if (image != null) {
                items.append("<td class=\"photo\" width=\"76\" style=\"width:76px;vertical-align:top\">")
                        .append("<img src=\"").append(escape(image)).append("\" alt=\"").append(escape(item.getProductName()))
                        .append("\" width=\"60\" height=\"80\" style=\"display:block;width:60px;height:80px;object-fit:cover;background:#f5f5f5;border:0\"></td>");
            }
            items.append("<td style=\"vertical-align:top\"><div style=\"font-size:14px;font-weight:600;line-height:1.6;color:#171717\">")
                    .append(escape(item.getProductName())).append("</div>")
                    .append("<div style=\"margin-top:4px;font-size:11px;line-height:1.7;color:#999;word-break:break-all\">SKU: ")
                    .append(escape(item.getSku())).append("</div>")
                    .append("<div style=\"margin-top:5px;font-size:12px;color:#777\">Số lượng: ")
                    .append(item.getQuantity()).append("</div></td></tr></table></td>")
                    .append("<td width=\"100\" align=\"right\" style=\"width:100px;padding:20px 0 20px 10px;border-bottom:1px solid #e7e7e7;vertical-align:top;font-size:14px;font-weight:500;white-space:nowrap;color:#171717\">")
                    .append(money(item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity())))).append("</td></tr>");
        }
        values.put("ITEMS", items.toString());
        var matcher = Pattern.compile("\\{\\{([A-Z_]+)}}").matcher(template);
        return matcher.replaceAll(match -> java.util.regex.Matcher.quoteReplacement(values.getOrDefault(match.group(1), "")));
    }

    private static String money(BigDecimal value) {
        return escape(NumberFormat.getCurrencyInstance(Locale.forLanguageTag("vi-VN")).format(value == null ? BigDecimal.ZERO : value));
    }

    private String safeImageUrl(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            var image = frontendUri.resolve(value.trim());
            if (!Set.of("http", "https").contains(image.getScheme()) || image.getHost() == null || image.getUserInfo() != null) return null;
            return image.toASCIIString();
        } catch (IllegalArgumentException invalid) { return null; }
    }

    static String escape(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
}
