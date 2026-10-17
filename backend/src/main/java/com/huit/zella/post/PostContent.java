package com.huit.zella.post;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.huit.zella.common.exception.BusinessException;
import org.springframework.http.HttpStatus;
import java.net.URI;
import java.util.Set;

/** Versioned Quill document; unprefixed content remains legacy plain text. */
public final class PostContent {
    public static final String PREFIX = "zella-quill-v1:";
    private static final ObjectMapper JSON = new ObjectMapper();
    private PostContent() {}

    public static String validate(String content) {
        if (content == null || content.isBlank() || content.length() > 100000) throw invalid();
        if (!content.startsWith(PREFIX)) return content.trim();
        try {
            JsonNode ops = JSON.readTree(content.substring(PREFIX.length()));
            if (!ops.isArray() || ops.isEmpty() || ops.size() > 10000) throw invalid();
            boolean meaningful = false;
            for (JsonNode op : ops) {
                if (!op.isObject() || op.has("delete") || op.has("retain")) throw invalid();
                JsonNode insert = op.get("insert");
                if (insert == null) throw invalid();
                if (insert.isTextual()) meaningful |= !insert.asText().isBlank();
                else if (insert.isObject() && insert.size() == 1 && insert.has("image") && insert.get("image").isTextual()) {
                    if (!safeUrl(insert.get("image").asText())) throw invalid();
                    meaningful = true;
                } else throw invalid();
                JsonNode attributes = op.get("attributes");
                if (attributes == null) continue;
                if (!attributes.isObject()) throw invalid();
                for (String key : new String[]{"bold", "italic", "underline", "strike", "blockquote"}) {
                    if (attributes.has(key) && !attributes.get(key).isBoolean()) throw invalid();
                }
                if (attributes.has("link") && (!attributes.get("link").isTextual() || !safeUrl(attributes.get("link").asText()))) throw invalid();
                if (attributes.has("header") && (!attributes.get("header").isIntegralNumber() || attributes.get("header").asInt() < 1 || attributes.get("header").asInt() > 6)) throw invalid();
                if (attributes.has("indent") && (!attributes.get("indent").isIntegralNumber() || attributes.get("indent").asInt() < 0 || attributes.get("indent").asInt() > 8)) throw invalid();
                if (attributes.has("list") && !Set.of("ordered", "bullet").contains(attributes.get("list").asText())) throw invalid();
                if (attributes.has("align") && !Set.of("left", "center", "right", "justify").contains(attributes.get("align").asText())) throw invalid();
            }
            JsonNode last = ops.get(ops.size() - 1).get("insert");
            if (!meaningful || !last.isTextual() || !last.asText().endsWith("\n")) throw invalid();
            return content;
        } catch (BusinessException e) { throw e; }
        catch (Exception e) { throw invalid(); }
    }

    private static boolean safeUrl(String value) {
        try {
            URI uri = URI.create(value);
            return ("https".equalsIgnoreCase(uri.getScheme()) || "http".equalsIgnoreCase(uri.getScheme()))
                    && uri.getHost() != null && uri.getRawUserInfo() == null && value.length() <= 2000;
        } catch (IllegalArgumentException e) { return false; }
    }
    private static BusinessException invalid() {
        return new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_POST_CONTENT", "Nội dung bài viết không hợp lệ; liên kết và ảnh phải dùng URL http hoặc https");
    }
}
