package com.huit.zella.mail;

import com.huit.zella.auth.User;
import com.huit.zella.order.*;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class OrderEmailsTest {
    final EmailQueue queue = mock(EmailQueue.class);
    final com.huit.zella.productimage.ProductImageRepository productImages = mock(com.huit.zella.productimage.ProductImageRepository.class);
    final com.huit.zella.variantimage.VariantImageRepository variantImages = mock(com.huit.zella.variantimage.VariantImageRepository.class);
    final OrderEmails emails = new OrderEmails(queue, new OrderEmailTemplate("https://shop.example"), productImages, variantImages);

    Order order() {
        when(queue.enabled()).thenReturn(true);
        Order order = new Order(); order.setCode("ORD-TEST"); order.setRecipientName("Nguyễn An");
        order.setRecipientEmail("guest@gmail.com"); order.setAddress("TP HCM");
        order.setRecipientPhone("0901234567"); order.setTotalAmount(new BigDecimal("480000"));
        OrderItem item = new OrderItem(); item.setProductName("Áo sơ mi"); item.setSku("AO-M");
        item.setQuantity(2); item.setUnitPrice(new BigDecimal("250000")); order.getItems().add(item);
        return order;
    }

    @Test void guestReceivesFinalTotalItemsAndDeliveryInformation() {
        Order order = order(); emails.enqueue(order, true);
        var captor = org.mockito.ArgumentCaptor.forClass(String.class);
        verify(queue).enqueueHtml(eq("guest@gmail.com"), contains("ORD-TEST"), captor.capture(), contains("<!doctype html>"), isNull());
        assertTrue(captor.getValue().contains("480.000"));
        assertTrue(captor.getValue().contains("Áo sơ mi (AO-M) x 2"));
        assertTrue(captor.getValue().contains("TP HCM"));
    }

    @Test void accountEmailIsFallbackAndStatusIsTranslated() {
        Order order = order(); order.setRecipientEmail(null); order.setStatus(OrderStatus.SHIPPED);
        User user = new User(); user.setEmail("account@gmail.com"); order.setCustomer(user);
        emails.enqueue(order, false);
        verify(queue).enqueueHtml(eq("account@gmail.com"), contains("Đang giao hàng"), anyString(), anyString(), isNull());
    }

    @Test void guestWithoutEmailDoesNotQueueMail() {
        Order order = order(); order.setRecipientEmail(null);
        emails.enqueue(order, true);
        verify(queue, never()).enqueueHtml(any(), any(), any(), any(), any());
    }

    @Test void variantPhotoIsPreferredAndProductPhotoIsFallback() {
        Order order = order(); var item = order.getItems().getFirst();
        var product = new com.huit.zella.product.Product(); product.setId(10L); item.setProduct(product);
        var variant = new com.huit.zella.productvariant.ProductVariant(); variant.setId(20L); item.setVariant(variant);
        var photo = new com.huit.zella.productimage.ProductImage(); photo.setProduct(product); photo.setImageUrl("https://cdn.example.com/product.jpg");
        var variantPhoto = new com.huit.zella.variantimage.VariantImage(); variantPhoto.setVariant(variant); variantPhoto.setImageUrl("https://cdn.example.com/variant.jpg");
        when(productImages.findByProductIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(java.util.List.of(10L))).thenReturn(java.util.List.of(photo));
        when(variantImages.findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(java.util.List.of(20L))).thenReturn(java.util.List.of(variantPhoto));
        emails.enqueue(order, true);
        verify(queue).enqueueHtml(anyString(), anyString(), anyString(), contains("variant.jpg"), isNull());
        clearInvocations(queue);
        when(variantImages.findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(java.util.List.of(20L))).thenReturn(java.util.List.of());
        emails.enqueue(order, true);
        verify(queue).enqueueHtml(anyString(), anyString(), anyString(), contains("product.jpg"), isNull());
    }
}
