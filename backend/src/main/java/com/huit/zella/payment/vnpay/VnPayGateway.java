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
        fields.put("vnp_Command", "querydr");
        fields.put("vnp_OrderInfo", "Query refund " + refund.getRequestId());
        return exchange(fields, QUERY_FIELDS, true);
    }

    private Map<String, String> common(PaymentRefund refund, String requestId, Instant now) {
        ensureConfigured();
        if (!properties.getTmnCode().equals(refund.getMerchantCode()))
            throw new IllegalStateException("Refund merchant changed");
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
            if (response.statusCode() != 200 || bytes.length > 65536) throw new IllegalStateException("Invalid VNPay HTTP response");
            Map<String, Object> raw = json.readValue(bytes, new TypeReference<>() {});
            Map<String, String> result = new LinkedHashMap<>();
            for (var field : raw.entrySet()) {
                Object scalar = field.getValue();
                String value;
                if (scalar instanceof String string) value = string;
                else if ((scalar instanceof Integer || scalar instanceof Long || scalar instanceof java.math.BigInteger)
                        && Set.of("vnp_Amount", "vnp_TransactionNo", "vnp_PromotionAmount").contains(field.getKey())) value = scalar.toString();
                else if (scalar == null && Set.of("vnp_PayDate", "vnp_PromotionCode", "vnp_PromotionAmount").contains(field.getKey())) value = "";
                else throw new IllegalStateException("Invalid VNPay response field");
                if (value.length() > 4096)
                    throw new IllegalStateException("Invalid VNPay response field");
                result.put(field.getKey(), value);
            }
            String received = result.get("vnp_SecureHash");
            String data = join(result, RESPONSE_FIELDS);
            if (query) data += "|" + result.getOrDefault("vnp_PromotionCode", "") + "|" + result.getOrDefault("vnp_PromotionAmount", "");
            if (received == null || !received.matches("[a-fA-F0-9]{128}")
                    || !MessageDigest.isEqual(HexFormat.of().parseHex(received), HexFormat.of().parseHex(VnPaySignature.signRaw(data, properties.getHashSecret())))
                    || !fields.get("vnp_Command").equals(result.get("vnp_Command"))
                    || !fields.get("vnp_TmnCode").equals(result.get("vnp_TmnCode"))
                    || !fields.get("vnp_TxnRef").equals(result.get("vnp_TxnRef")))
                throw new IllegalStateException("Unverified VNPay response");
            if (!query && (!fields.get("vnp_Amount").equals(result.get("vnp_Amount"))
                    || !fields.get("vnp_TransactionType").equals(result.get("vnp_TransactionType"))
                    || !fields.get("vnp_OrderInfo").equals(result.get("vnp_OrderInfo"))))
                throw new IllegalStateException("Refund response mismatch");
            return result;
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt(); throw new IllegalStateException("VNPay request interrupted", ex);
        } catch (java.io.IOException ex) { throw new IllegalStateException("VNPay response unavailable", ex); }
    }

    static String minorAmount(PaymentRefund refund) { return refund.getAmount().movePointRight(2).toBigIntegerExact().toString(); }
    static String join(Map<String, String> fields, String... names) {
        return String.join("|", Arrays.stream(names).map(name -> fields.getOrDefault(name, "")).toList());
    }
}
