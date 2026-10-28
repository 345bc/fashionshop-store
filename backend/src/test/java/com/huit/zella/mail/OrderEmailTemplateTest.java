package com.huit.zella.mail;

import com.huit.zella.order.*;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.nio.file.*;
import java.time.LocalDateTime;
import static org.junit.jupiter.api.Assertions.*;

class OrderEmailTemplateTest {
    private final OrderEmailTemplate template = new OrderEmailTemplate("https://fashionshop-store.vercel.app");

    private Order sample() {
        Order order = new Order(); order.setCode("ORD-12665E6454B4488082880F285774");
        order.setRecipientName("Nguyễn Tấn Tuấn"); order.setRecipientPhone("0901234567");
        order.setAddress("140 Lê Trọng Tấn, Phường Tân Phú, Thành phố Hồ Chí Minh");
        order.setCreatedAt(LocalDateTime.of(2026, 10, 21, 8, 45));
        order.setSubtotal(new BigDecimal("611000")); order.setTotalAmount(new BigDecimal("611000"));
        OrderItem item = new OrderItem(); item.setProductName("Váy Midi Sage Flow"); item.setSku("vay-midi-sage-flow-TAN-M");
        item.setQuantity(1); item.setUnitPrice(new BigDecimal("611000")); order.getItems().add(item);
        return order;
    }

    @Test void rendersAllOrderStatesWithoutUnresolvedPlaceholders() {
        Order order = sample();
        for (OrderStatus status : OrderStatus.values()) {
            order.setStatus(status);
            String html = template.render(order, false, "Trạng thái đơn", "Chờ thanh toán");
            assertFalse(html.contains("{{")); assertTrue(html.contains("611.000"));
            assertTrue(html.contains("Váy Midi Sage Flow"));
            assertTrue(html.contains("21.10.2026 · 15:45"));
            assertTrue(html.contains("https://fashionshop-store.vercel.app/order-tracking"));
        }
    }

    @Test void userContentIsEscapedAndCannotInjectMarkupOrReplaceTemplateTokens() {
        Order order = sample(); order.setRecipientName("<img src=x onerror=alert(1)>");
        order.setAddress("Địa chỉ & \"ghi chú\" {{TOTAL}}");
        order.getItems().getFirst().setProductName("<script>alert(1)</script>");
        String html = template.render(order, true, "Chờ thanh toán", "Chờ thanh toán");
        assertFalse(html.contains("<script>")); assertFalse(html.contains("<img src=x"));
        assertTrue(html.contains("&lt;img src=x onerror=alert(1)&gt;"));
        assertTrue(html.contains("Địa chỉ &amp; &quot;ghi chú&quot; {{TOTAL}}"));
    }

    @Test void cancelledOrderShowsOrderValueAndCreatesVisualPreview() throws Exception {
        Order order = sample(); order.setStatus(OrderStatus.CANCELLED);
        String html = template.render(order, false, "Đã hủy", "Chờ thanh toán");
        assertTrue(html.contains("Giá trị đơn hàng"));
        assertTrue(html.contains("Đơn hàng đã được hủy."));
        Path directory = Path.of("target", "email-previews"); Files.createDirectories(directory);
        Files.writeString(directory.resolve("order-cancelled.html"), html);
        order.setStatus(OrderStatus.CONFIRMED);
        Files.writeString(directory.resolve("order-confirmed.html"), template.render(order, false, "Đã xác nhận", "Đã thanh toán"));
        var item = order.getItems().getFirst();
        item.setProductName("Túi cói Natural"); item.setSku("TUI-COI-NATURAL");
        Files.writeString(directory.resolve("order-with-photo.html"), template.render(order, false, "Đã xác nhận", "Đã thanh toán",
                java.util.Map.of(item, "https://preview.example.com/product.png")));
    }

    @Test void invalidFrontendUrlsCannotBecomeEmailLinks() {
        assertThrows(IllegalArgumentException.class, () -> new OrderEmailTemplate("javascript:alert(1)"));
        assertThrows(IllegalArgumentException.class, () -> new OrderEmailTemplate("https://example.com/?redirect=bad"));
    }

    @Test void productPhotoIsRenderedOnlyForSafeWebUrls() {
        Order order = sample(); var item = order.getItems().getFirst();
        String html = template.render(order, false, "Đã xác nhận", "Đã thanh toán",
                java.util.Map.of(item, "https://cdn.example.com/dress.jpg?size=small&fit=crop"));
        assertTrue(html.contains("<img src=\"https://cdn.example.com/dress.jpg?size=small&amp;fit=crop\""));
        String invalid = template.render(order, false, "Đã xác nhận", "Đã thanh toán",
                java.util.Map.of(item, "javascript:alert(1)"));
        assertFalse(invalid.contains("<img"));
        assertFalse(invalid.contains("EVERYDAY"));
        assertFalse(invalid.contains("Georgia"));
    }
}
