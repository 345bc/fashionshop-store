package com.huit.zella.payment.vnpay;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.*;
import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.time.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import static org.junit.jupiter.api.Assertions.*;

class VnPayServiceTest {
    private final Clock clock = Clock.fixed(Instant.parse("2026-10-09T00:00:00Z"), ZoneOffset.UTC);
    private final Order order = order();
    private final VnPayProperties properties = properties();
    private int paymentCalls;
    private final OrderRepository repository = (OrderRepository) Proxy.newProxyInstance(
            OrderRepository.class.getClassLoader(), new Class<?>[]{OrderRepository.class}, (proxy, method, args) -> {
                if (method.getName().equals("findByIdForUpdate")) return order.getId().equals(args[0]) ? Optional.of(order) : Optional.empty();
                if (method.getName().equals("flush")) return null;
                throw new UnsupportedOperationException(method.getName());
            });
    private final OrderService orders = new OrderService(repository, null, null, null, clock, null, null, org.mockito.Mockito.mock(com.huit.zella.loyalty.LoyaltyService.class), org.mockito.Mockito.mock(com.huit.zella.voucher.VoucherService.class), org.mockito.Mockito.mock(com.huit.zella.mail.OrderEmails.class)) {
        @Override public CheckoutOrderResponse checkoutStatus(String code, String token) {
            if (!"checkout-token".equals(token)) throw new BusinessException(org.springframework.http.HttpStatus.FORBIDDEN, "TOKEN", "Invalid token");
            return new CheckoutOrderResponse(order.getId(), code, "PENDING", "PENDING", order.getTotalAmount(), null, null, List.of(), order.getSubtotal(), order.getShippingFee(), order.getDiscountAmount(), null);
        }
        @Override public OrderResponse recordOnlinePayment(Long id, BigDecimal amount, String reference) {
            paymentCalls++;
            assertEquals(order.getId(), id); assertEquals(0, order.getTotalAmount().compareTo(amount));
            assertEquals("VNPAY-123456", reference); order.setOnlineTransactionId(reference);
            return null;
        }
    };
    private final VnPayService service = new VnPayService(properties, orders, repository, clock);

    @Test void buildsSignedSandboxUrlWithServerAmountAndFiveMinuteExpiryInVietnamTime() {
        String url = service.payment(order.getCode(), "checkout-token", "127.0.0.1").checkoutUrl();
        assertTrue(url.startsWith("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?"));
        MultiValueMap<String, String> query = parse(url);
        assertEquals("53000000", query.getFirst("vnp_Amount"));
        assertEquals("20261009070000", query.getFirst("vnp_CreateDate"));
        assertEquals("20261009070500", query.getFirst("vnp_ExpireDate"));
        assertEquals("123", query.getFirst("vnp_TxnRef"));
        assertNotNull(VnPaySignature.verify(query, properties.getHashSecret()));
        assertEquals(url, service.payment(order.getCode(), "checkout-token", "127.0.0.2").checkoutUrl());
    }

    @Test void rejectsInvalidCheckoutTokenExpiredOrderAndMissingConfiguration() {
        assertThrows(BusinessException.class, () -> service.payment(order.getCode(), "wrong", "127.0.0.1"));
        order.setPaymentExpiresAt(LocalDateTime.now(clock));
        assertThrows(BusinessException.class, () -> service.payment(order.getCode(), "checkout-token", "127.0.0.1"));
        properties.setEnabled(false);
        assertThrows(BusinessException.class, service::ensureConfigured);
    }

    @Test void verifiesIndependentHmacFixtureAndRejectsTamperedOrDuplicateParameters() {
        Map<String, String> fields = Map.of("vnp_Amount", "53000000", "vnp_OrderInfo", "Thanh toan don hang 123", "vnp_TmnCode", "TEST1234");
        String signature = "e8e45afc323067def0f85ec41dbec385fd36f765afcc70ac7310dc7023938ebac3434748180a11e6834c3e49e23c513fc6e7ba9a7b1ce8f741540c1ad5e80037";
        assertEquals(signature, VnPaySignature.sign(fields, "sandbox-secret"));
        MultiValueMap<String, String> query = new LinkedMultiValueMap<>(); fields.forEach(query::add); query.add("vnp_SecureHash", signature);
        assertNotNull(VnPaySignature.verify(query, "sandbox-secret"));
        query.set("vnp_Amount", "1"); assertNull(VnPaySignature.verify(query, "sandbox-secret"));
        query.set("vnp_Amount", "53000000"); query.add("vnp_Amount", "53000000");
        assertNull(VnPaySignature.verify(query, "sandbox-secret"));
    }

    @Test void successfulIpnUpdatesExactlyOnceAndAcknowledgesRepeatedIpn() {
        service.payment(order.getCode(), "checkout-token", "127.0.0.1");
        assertEquals("00", service.ipn(callback("53000000", "TEST1234", "00")).get("RspCode"));
        assertEquals("02", service.ipn(callback("53000000", "TEST1234", "00")).get("RspCode"));
        assertEquals(1, paymentCalls);
    }

    @Test void rejectsWrongAmountWrongMerchantAndUnsignedCallback() {
        service.payment(order.getCode(), "checkout-token", "127.0.0.1");
        assertEquals("04", service.ipn(callback("50000000", "TEST1234", "00")).get("RspCode"));
        assertEquals("97", service.ipn(callback("53000000", "OTHER123", "00")).get("RspCode"));
        assertEquals("97", service.ipn(new LinkedMultiValueMap<>()).get("RspCode"));
        assertEquals(0, paymentCalls);
    }

    @Test void unsuccessfulIpnAndUnknownOrderNeverConfirmPayment() {
        service.payment(order.getCode(), "checkout-token", "127.0.0.1");
        assertEquals("00", service.ipn(callback("53000000", "TEST1234", "24")).get("RspCode"));
        order.setId(999L);
        assertEquals("01", service.ipn(callback("53000000", "TEST1234", "00")).get("RspCode"));
        assertEquals(0, paymentCalls);
    }

    @Test void localReturnVerifiesPaymentOnceAndRejectsInvalidData() {
        properties.setIpnRequired(false);
        service.payment(order.getCode(), "checkout-token", "127.0.0.1");
        assertThrows(BusinessException.class, () -> service.verifyReturn(order.getCode(), "wrong", callback("53000000", "TEST1234", "00")));
        assertEquals("04", service.verifyReturn(order.getCode(), "checkout-token", callback("1", "TEST1234", "00")).get("RspCode"));
        assertEquals("97", service.verifyReturn(order.getCode(), "checkout-token", callback("53000000", "OTHER123", "00")).get("RspCode"));
        var mismatched = callback("53000000", "TEST1234", "00");
        mismatched.set("vnp_TxnRef", "456");
        assertEquals("01", service.verifyReturn(order.getCode(), "checkout-token", mismatched).get("RspCode"));
        var tampered = callback("53000000", "TEST1234", "00");
        tampered.set("vnp_TransactionNo", "999999");
        assertEquals("97", service.verifyReturn(order.getCode(), "checkout-token", tampered).get("RspCode"));
        assertEquals(0, paymentCalls);
        assertEquals("00", service.verifyReturn(order.getCode(), "checkout-token", callback("53000000", "TEST1234", "00")).get("RspCode"));
        assertEquals("02", service.ipn(callback("53000000", "TEST1234", "00")).get("RspCode"));
        assertEquals(1, paymentCalls);
    }

    @Test void productionModeDoesNotConfirmBrowserReturn() {
        assertTrue(properties.isIpnRequired());
        service.payment(order.getCode(), "checkout-token", "127.0.0.1");
        service.verifyReturn(order.getCode(), "checkout-token", callback("53000000", "TEST1234", "00"));
        assertEquals(0, paymentCalls);
        assertEquals("00", service.ipn(callback("53000000", "TEST1234", "00")).get("RspCode"));
        assertEquals(1, paymentCalls);
    }

    @Test void localReturnRejectsLiveGatewayAndPublicReturnUrl() {
        properties.setIpnRequired(false);
        properties.setPaymentUrl("https://pay.vnpay.vn/paymentv2/vpcpay.html");
        assertThrows(BusinessException.class, () -> service.verifyReturn(order.getCode(), "checkout-token", callback("53000000", "TEST1234", "00")));
        properties.setPaymentUrl("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html");
        properties.setReturnUrl("https://zella.example/checkout");
        assertThrows(BusinessException.class, () -> service.verifyReturn(order.getCode(), "checkout-token", callback("53000000", "TEST1234", "00")));
        assertEquals(0, paymentCalls);
    }

    @Test void refusesUntrustedGatewayUrl() {
        assertFalse(VnPayService.validPaymentUrl("https://sandbox.vnpayment.vn.attacker.test/paymentv2/vpcpay.html"));
        assertFalse(VnPayService.validPaymentUrl("http://sandbox.vnpayment.vn/paymentv2/vpcpay.html"));
        assertTrue(VnPayService.validPaymentUrl("https://pay.vnpay.vn/paymentv2/vpcpay.html"));
    }

    private MultiValueMap<String, String> callback(String amount, String merchant, String status) {
        Map<String, String> fields = Map.of("vnp_Amount", amount, "vnp_TmnCode", merchant, "vnp_TxnRef", "123",
                "vnp_TransactionNo", "123456", "vnp_ResponseCode", status, "vnp_TransactionStatus", status);
        MultiValueMap<String, String> query = new LinkedMultiValueMap<>(); fields.forEach(query::add);
        query.add("vnp_SecureHash", VnPaySignature.sign(fields, properties.getHashSecret())); return query;
    }
    private MultiValueMap<String, String> parse(String url) {
        MultiValueMap<String, String> result = new LinkedMultiValueMap<>();
        for (String part : URI.create(url).getRawQuery().split("&")) {
            String[] pair = part.split("=", 2);
            result.add(URLDecoder.decode(pair[0], StandardCharsets.UTF_8), URLDecoder.decode(pair[1], StandardCharsets.UTF_8));
        }
        return result;
    }
    private Order order() {
        Order value = new Order(); value.setId(123L); value.setCode("ORD-123"); value.setTotalAmount(new BigDecimal("530000"));
        value.setPaymentExpiresAt(LocalDateTime.now(clock).plusMinutes(5)); return value;
    }
    private VnPayProperties properties() {
        VnPayProperties value = new VnPayProperties(); value.setEnabled(true); value.setTmnCode("TEST1234");
        value.setHashSecret("sandbox-secret"); return value;
    }
}
