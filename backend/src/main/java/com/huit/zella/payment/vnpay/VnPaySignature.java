package com.huit.zella.payment.vnpay;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;
import java.util.stream.Collectors;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.util.MultiValueMap;

final class VnPaySignature {
    private VnPaySignature() {}

    static String query(Map<String, String> fields) {
        return new TreeMap<>(fields).entrySet().stream()
                .filter(entry -> entry.getValue() != null && !entry.getValue().isEmpty())
                .map(entry -> encode(entry.getKey()) + "=" + encode(entry.getValue()))
                .collect(Collectors.joining("&"));
    }

    static String sign(Map<String, String> fields, String secret) {
        return signRaw(query(fields), secret);
    }

    static String signRaw(String data, String secret) {
        try {
            Mac mac = Mac.getInstance("HmacSHA512");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
            return HexFormat.of().formatHex(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (java.security.GeneralSecurityException ex) { throw new IllegalStateException("Cannot sign VNPay request", ex); }
    }

    static Map<String, String> verify(MultiValueMap<String, String> input, String secret) {
        Map<String, String> fields = new TreeMap<>();
        if (input.size() > 50) return null;
        for (var entry : input.entrySet()) {
            if (!entry.getKey().startsWith("vnp_")) continue;
            if (entry.getValue() == null || entry.getValue().size() != 1 || entry.getValue().getFirst() == null
                    || entry.getValue().getFirst().length() > 2048) return null;
            fields.put(entry.getKey(), entry.getValue().getFirst());
        }
        String received = fields.remove("vnp_SecureHash");
        fields.remove("vnp_SecureHashType");
        if (received == null || !received.matches("[a-fA-F0-9]{128}")) return null;
        return MessageDigest.isEqual(HexFormat.of().parseHex(received), HexFormat.of().parseHex(sign(fields, secret))) ? fields : null;
    }

    private static String encode(String value) { return URLEncoder.encode(value, StandardCharsets.UTF_8); }
}
