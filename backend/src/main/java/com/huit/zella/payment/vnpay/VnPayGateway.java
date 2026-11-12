package com.huit.zella.payment.vnpay;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.huit.zella.common.exception.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.beans.factory.annotation.Autowired;
import java.net.URI;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;

/** JSON API uses pipe-separated HMAC data, unlike the payment URL signature. */
@Component
public class VnPayGateway {
    static final class GatewayFailure extends IllegalStateException {
        private final String responseCode;

        GatewayFailure(String reason) {
            this(reason, null, null);
        }

        GatewayFailure(String reason, Throwable cause) {
            this(reason, cause, null);
        }

        GatewayFailure(String reason, Throwable cause, String responseCode) {
            super(reason, cause);
            this.responseCode = responseCode != null && responseCode.matches("[0-9]{2}") ? responseCode : null;
        }

        String responseCode() {
            return responseCode;
        }
    }

    private static final String[] REFUND_FIELDS = {"vnp_RequestId", "vnp_Version", "vnp_Command", "vnp_TmnCode",
        "vnp_TransactionType", "vnp_TxnRef", "vnp_Amount", "vnp_TransactionNo", "vnp_TransactionDate",
        "vnp_CreateBy", "vnp_CreateDate", "vnp_IpAddr", "vnp_OrderInfo"};
    private static final String[] QUERY_FIELDS = {"vnp_RequestId", "vnp_Version", "vnp_Command", "vnp_TmnCode",
        "vnp_TxnRef", "vnp_TransactionDate", "vnp_CreateDate", "vnp_IpAddr", "vnp_OrderInfo"};
    private static final String[] RESPONSE_FIELDS = {"vnp_ResponseId", "vnp_Command", "vnp_ResponseCode", "vnp_Message",
        "vnp_TmnCode", "vnp_TxnRef", "vnp_Amount", "vnp_BankCode", "vnp_PayDate", "vnp_TransactionNo",
        "vnp_TransactionType", "vnp_TransactionStatus", "vnp_OrderInfo"};
    private final VnPayProperties properties;
    private final HttpClient client;
    private final ObjectMapper json = new ObjectMapper().enable(JsonParser.Feature.STRICT_DUPLICATE_DETECTION);

    @Autowired
    public VnPayGateway(VnPayProperties properties) {
        this(properties, HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5))
            .followRedirects(HttpClient.Redirect.NEVER).build());
    }

    VnPayGateway(VnPayProperties properties, HttpClient client) {
        this.properties = properties; this.client = client;
    }

    public void ensureConfigured() {
        try {
            URI payment = URI.create(properties.getPaymentUrl()), api = URI.create(properties.getApiUrl());
            if (!properties.isEnabled() || !properties.isRefundEnabled()
                    || !properties.getTmnCode().matches("[A-Za-z0-9]{8}") || properties.getHashSecret().isBlank()
                    || !VnPayService.validPaymentUrl(properties.getPaymentUrl())
                    || !Objects.equals(payment.getHost(), api.getHost()) || !"https".equals(api.getScheme())
                    || !"/merchant_webapi/api/transaction".equals(api.getPath()) || api.getUserInfo() != null
                    || api.getQuery() != null || api.getFragment() != null || (api.getPort() != -1 && api.getPort() != 443)
                    || !literalIp(properties.getServerIp())) throw new IllegalArgumentException();
        } catch (IllegalArgumentException | NullPointerException ex) {
            throw new BusinessException(HttpStatus.SERVICE_UNAVAILABLE, "REFUND_NOT_CONFIGURED", "API hoàn tiền VNPay chưa được cấu hình đúng");
        }
    }

    private static boolean literalIp(String value) {
        if (value == null || value.length() > 45 || !value.matches("[0-9a-fA-F:.]+")) return false;
        if (value.contains(":")) {
            try { java.net.InetAddress.getByName(value); return true; }
            catch (java.net.UnknownHostException ex) { return false; }
        }
        String[] parts = value.split("\\.", -1);
        return parts.length == 4 && Arrays.stream(parts).allMatch(part -> part.matches("[0-9]{1,3}") && Integer.parseInt(part) <= 255);
    }

    public Map<String, String> refund(PaymentRefund refund, Instant now) {
        var fields = common(refund, refund.getRequestId(), now);
        fields.put("vnp_Command", "refund"); fields.put("vnp_Amount", minorAmount(refund));
        fields.put("vnp_TransactionType", refund.getTransactionType());
        fields.put("vnp_CreateBy", "admin-" + refund.getActorId());
        fields.put("vnp_OrderInfo", "Refund " + refund.getRequestId());
        return exchange(fields, REFUND_FIELDS, false);
    }

    public Map<String, String> query(PaymentRefund refund, Instant now) {
        var fields = common(refund, UUID.randomUUID().toString().replace("-", ""), now);
        fields.remove("vnp_TransactionNo");
        fields.put("vnp_Command", "querydr");
        fields.put("vnp_OrderInfo", "Query refund " + refund.getRequestId());
        return exchange(fields, QUERY_FIELDS, true);
    }

    private Map<String, String> common(PaymentRefund refund, String requestId, Instant now) {
        ensureConfigured();
        if (!properties.getTmnCode().equals(refund.getMerchantCode()))
            throw new GatewayFailure("MERCHANT_CHANGED");
        Map<String, String> fields = new LinkedHashMap<>();
        fields.put("vnp_RequestId", requestId); fields.put("vnp_Version", "2.1.0");
        fields.put("vnp_TmnCode", refund.getMerchantCode()); fields.put("vnp_TxnRef", refund.getOrderId().toString());
        fields.put("vnp_TransactionNo", refund.getTransactionNo()); fields.put("vnp_TransactionDate", refund.getTransactionDate());
        fields.put("vnp_CreateDate", DateTimeFormatter.ofPattern("yyyyMMddHHmmss").format(now.atZone(ZoneId.of("Asia/Ho_Chi_Minh"))));
        fields.put("vnp_IpAddr", properties.getServerIp());
        return fields;
    }

    private Map<String, String> exchange(Map<String, String> fields, String[] signingFields, boolean query) {
        try {
            fields.put("vnp_SecureHash", VnPaySignature.signRaw(join(fields, signingFields), properties.getHashSecret()));
            HttpRequest request = HttpRequest.newBuilder(URI.create(properties.getApiUrl())).timeout(Duration.ofSeconds(15))
                .header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(fields))).build();
            var response = client.send(request, HttpResponse.BodyHandlers.ofInputStream());
            byte[] bytes;
            try (var body = response.body()) { bytes = body.readNBytes(65537); }
            if (response.statusCode() != 200) throw new GatewayFailure("HTTP_" + response.statusCode());
            if (bytes.length > 65536) throw new GatewayFailure("RESPONSE_TOO_LARGE");
            Map<String, Object> raw = json.readValue(bytes, new TypeReference<>() {});
            Map<String, String> result = new LinkedHashMap<>();
            for (var field : raw.entrySet()) {
                Object scalar = field.getValue();
                String value;
                if (scalar instanceof String string) value = string;
                else if ((scalar instanceof Integer || scalar instanceof Long || scalar instanceof java.math.BigInteger)
                        && Set.of("vnp_Amount", "vnp_TransactionNo", "vnp_PromotionAmount").contains(field.getKey())) value = scalar.toString();
                else if (scalar == null && Set.of("vnp_PayDate", "vnp_PromotionCode", "vnp_PromotionAmount").contains(field.getKey())) value = "";
                else throw new GatewayFailure("INVALID_RESPONSE_FIELD");
                if (value.length() > 4096)
                    throw new GatewayFailure("INVALID_RESPONSE_FIELD");
                result.put(field.getKey(), value);
            }
            String received = result.get("vnp_SecureHash");
            String data = join(result, RESPONSE_FIELDS);
            if (query) data += "|" + result.getOrDefault("vnp_PromotionCode", "") + "|" + result.getOrDefault("vnp_PromotionAmount", "");
            if (received == null || received.isBlank())
                throw new GatewayFailure("MISSING_RESPONSE_SIGNATURE", null, result.get("vnp_ResponseCode"));
            if (!received.matches("[a-fA-F0-9]{128}"))
                throw new GatewayFailure("INVALID_RESPONSE_SIGNATURE_FORMAT", null, result.get("vnp_ResponseCode"));
            if (!MessageDigest.isEqual(HexFormat.of().parseHex(received),
                    HexFormat.of().parseHex(VnPaySignature.signRaw(data, properties.getHashSecret()))))
                throw new GatewayFailure("RESPONSE_SIGNATURE_MISMATCH");
            String command = result.getOrDefault("vnp_Command", "");
            if (!(query && command.isEmpty()) && !fields.get("vnp_Command").equals(command))
                throw new GatewayFailure("RESPONSE_COMMAND_MISMATCH");
            if (!fields.get("vnp_TmnCode").equals(result.get("vnp_TmnCode"))
                    || !fields.get("vnp_TxnRef").equals(result.get("vnp_TxnRef")))
                throw new GatewayFailure("RESPONSE_TRANSACTION_MISMATCH");
            if (!query && (!fields.get("vnp_Amount").equals(result.get("vnp_Amount"))
                    || !fields.get("vnp_TransactionType").equals(result.get("vnp_TransactionType"))
                    || !fields.get("vnp_OrderInfo").equals(result.get("vnp_OrderInfo"))))
                throw new GatewayFailure("REFUND_RESPONSE_MISMATCH");
            return result;
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt(); throw new GatewayFailure("REQUEST_INTERRUPTED", ex);
        } catch (com.fasterxml.jackson.core.JsonProcessingException ex) {
            throw new GatewayFailure("INVALID_JSON", ex);
        } catch (java.io.IOException ex) {
            throw new GatewayFailure("TRANSPORT_ERROR", ex);
        }
    }

    static String minorAmount(PaymentRefund refund) { return refund.getAmount().movePointRight(2).toBigIntegerExact().toString(); }
    static String join(Map<String, String> fields, String... names) {
        return String.join("|", Arrays.stream(names).map(name -> fields.getOrDefault(name, "")).toList());
    }
}
