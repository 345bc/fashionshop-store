package com.huit.zella.payment.vnpay;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.huit.zella.common.exception.BusinessException;
import org.junit.jupiter.api.*;
import java.io.*;
import java.math.BigDecimal;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.*;
import java.nio.ByteBuffer;
import java.util.concurrent.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

class VnPayGatewayTest {
    private final VnPayProperties config = new VnPayProperties();
    private final HttpClient client = mock(HttpClient.class);
    private final VnPayGateway gateway = new VnPayGateway(config, client);
    private final PaymentRefund refund = new PaymentRefund();
    private final ObjectMapper json = new ObjectMapper();
    private final Instant now = Instant.parse("2026-10-15T08:00:00Z");
    private static final String RESPONSE_ORDER = "vnp_ResponseId|vnp_Command|vnp_ResponseCode|vnp_Message|vnp_TmnCode|vnp_TxnRef|vnp_Amount|vnp_BankCode|vnp_PayDate|vnp_TransactionNo|vnp_TransactionType|vnp_TransactionStatus|vnp_OrderInfo";
    @BeforeEach void setup() {
        config.setEnabled(true); config.setRefundEnabled(true); config.setTmnCode("TEST1234"); config.setHashSecret("test-secret");
        refund.setRequestId("request123"); refund.setMerchantCode("TEST1234"); refund.setOrderId(1L);
        refund.setActorId(9L); refund.setAmount(new BigDecimal("100000")); refund.setTransactionNo("12345");
        refund.setTransactionType("02"); refund.setTransactionDate("20261015140000");
    }
    private Map<String, String> response() {
        var result = new LinkedHashMap<String, String>();
        result.put("vnp_ResponseId", "response123"); result.put("vnp_Command", "refund"); result.put("vnp_ResponseCode", "00");
        result.put("vnp_Message", "Success"); result.put("vnp_TmnCode", "TEST1234"); result.put("vnp_TxnRef", "1");
        result.put("vnp_Amount", "10000000"); result.put("vnp_BankCode", "NCB"); result.put("vnp_PayDate", "20261015150000");
        result.put("vnp_TransactionNo", "98765"); result.put("vnp_TransactionType", "02"); result.put("vnp_TransactionStatus", "00");
        result.put("vnp_OrderInfo", "Refund request123"); return result;
    }
    private void sign(Map<String, String> fields, boolean query) throws Exception {
        String order = RESPONSE_ORDER + (query ? "|vnp_PromotionCode|vnp_PromotionAmount" : "");
        String raw = String.join("|", Arrays.stream(order.split("\\|")).map(k -> fields.getOrDefault(k, "")).toList());
        Mac mac = Mac.getInstance("HmacSHA512"); mac.init(new SecretKeySpec("test-secret".getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
        fields.put("vnp_SecureHash", HexFormat.of().formatHex(mac.doFinal(raw.getBytes(StandardCharsets.UTF_8))));
    }
    @SuppressWarnings("unchecked") private void respond(String body, int status) throws Exception {
        HttpResponse<InputStream> response = mock(HttpResponse.class);
        when(response.statusCode()).thenReturn(status); when(response.body()).thenReturn(new ByteArrayInputStream(body.getBytes(StandardCharsets.UTF_8)));
        when(client.send(any(HttpRequest.class), any(HttpResponse.BodyHandler.class))).thenReturn(response);
    }
    @Test void acceptsIndependentlySignedResponse() throws Exception {
        var fields = response(); sign(fields, false); respond(json.writeValueAsString(fields), 200);
        assertEquals("98765", gateway.refund(refund, now).get("vnp_TransactionNo"));
    }
    @Test void refundRequestUsesOriginalTransactionDateServerAmountAndPipeSeparatedHmac() throws Exception {
        var fields = response(); sign(fields, false); respond(json.writeValueAsString(fields), 200);
        gateway.refund(refund, now);
        var captured = org.mockito.ArgumentCaptor.forClass(HttpRequest.class);
        verify(client).send(captured.capture(), any(HttpResponse.BodyHandler.class));
        HttpRequest request = captured.getValue();
        CompletableFuture<String> body = new CompletableFuture<>();
        request.bodyPublisher().orElseThrow().subscribe(new Flow.Subscriber<ByteBuffer>() {
            final ByteArrayOutputStream bytes = new ByteArrayOutputStream();
            public void onSubscribe(Flow.Subscription subscription) { subscription.request(Long.MAX_VALUE); }
            public void onNext(ByteBuffer buffer) { byte[] part = new byte[buffer.remaining()]; buffer.get(part); bytes.writeBytes(part); }
            public void onError(Throwable cause) { body.completeExceptionally(cause); }
            public void onComplete() { body.complete(bytes.toString(StandardCharsets.UTF_8)); }
        });
        var payload = json.readTree(body.get(2, TimeUnit.SECONDS));
        assertEquals("20261015140000", payload.get("vnp_TransactionDate").asText());
        assertEquals("20261015150000", payload.get("vnp_CreateDate").asText());
        assertEquals("10000000", payload.get("vnp_Amount").asText());
        String raw = "request123|2.1.0|refund|TEST1234|02|1|10000000|12345|20261015140000|admin-9|20261015150000|127.0.0.1|Refund request123";
        Mac mac = Mac.getInstance("HmacSHA512"); mac.init(new SecretKeySpec("test-secret".getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
        assertEquals(HexFormat.of().formatHex(mac.doFinal(raw.getBytes(StandardCharsets.UTF_8))), payload.get("vnp_SecureHash").asText());
    }
    @Test void rejectsTamperedSignature() throws Exception {
        var fields = response(); sign(fields, false); fields.put("vnp_Amount", "1"); respond(json.writeValueAsString(fields), 200);
        assertThrows(IllegalStateException.class, () -> gateway.refund(refund, now));
    }
    @Test void acceptsIntegerAmountAndTransactionNumberWithoutLosingSignaturePrecision() throws Exception {
        var fields = response(); sign(fields, false);
        String body = json.writeValueAsString(fields).replace("\"vnp_Amount\":\"10000000\"", "\"vnp_Amount\":10000000")
            .replace("\"vnp_TransactionNo\":\"98765\"", "\"vnp_TransactionNo\":98765");
        respond(body, 200); assertEquals("98765", gateway.refund(refund, now).get("vnp_TransactionNo"));
    }
    @Test void rejectsSignedResponseForAnotherMerchantOrderAmountOrRequest() throws Exception {
        for (var mismatch : Map.of("vnp_TmnCode", "OTHER123", "vnp_TxnRef", "2", "vnp_Amount", "1",
                "vnp_TransactionType", "03", "vnp_OrderInfo", "Refund another-request").entrySet()) {
            var fields = response(); fields.put(mismatch.getKey(), mismatch.getValue()); sign(fields, false);
            respond(json.writeValueAsString(fields), 200);
            assertThrows(IllegalStateException.class, () -> gateway.refund(refund, now), mismatch.getKey());
        }
    }
    @Test void rejectsHttpErrorMalformedAndDuplicateJsonFields() throws Exception {
        respond("{}", 503); assertThrows(IllegalStateException.class, () -> gateway.refund(refund, now));
        respond("not json", 200); assertThrows(IllegalStateException.class, () -> gateway.refund(refund, now));
        respond("{\"vnp_Command\":\"refund\",\"vnp_Command\":\"refund\"}", 200);
        assertThrows(IllegalStateException.class, () -> gateway.refund(refund, now));
    }
    @Test void queryUsesItsOwnSignatureIncludingPromotionFields() throws Exception {
        var fields = response(); fields.put("vnp_Command", "querydr"); fields.put("vnp_PromotionCode", "TEST"); fields.put("vnp_PromotionAmount", "0");
        sign(fields, true); respond(json.writeValueAsString(fields), 200);
        assertEquals("00", gateway.query(refund, now).get("vnp_ResponseCode"));
    }
    @Test void rejectsDisabledRefundsForeignHostsMixedEnvironmentsAndRedirectUrls() {
        config.setRefundEnabled(false); assertThrows(BusinessException.class, gateway::ensureConfigured);
        config.setRefundEnabled(true);
        for (String url : List.of("http://sandbox.vnpayment.vn/merchant_webapi/api/transaction", "https://evil.example/merchant_webapi/api/transaction",
            "https://pay.vnpay.vn/merchant_webapi/api/transaction", "https://sandbox.vnpayment.vn/merchant_webapi/api/transaction?redirect=1")) {
            config.setApiUrl(url); assertThrows(BusinessException.class, gateway::ensureConfigured);
        }
        config.setApiUrl("https://sandbox.vnpayment.vn/merchant_webapi/api/transaction");
        config.setServerIp("999.999.999.999"); assertThrows(BusinessException.class, gateway::ensureConfigured);
    }
}
