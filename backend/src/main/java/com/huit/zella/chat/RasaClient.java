package com.huit.zella.chat;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.huit.zella.common.exception.BusinessException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Component
public class RasaClient {
    public record Result(List<ChatResponse.Message> messages, String intent, boolean fallback) {}

    private final String baseUrl;
    private final String token;
    private final Duration timeout;
    private final ObjectMapper json = new ObjectMapper();
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

    public RasaClient(@Value("${app.chat.rasa.base-url:http://127.0.0.1:5005}") String baseUrl,
                      @Value("${app.chat.rasa.auth-token:}") String token,
                      @Value("${app.chat.rasa.timeout-seconds:60}") long timeoutSeconds) {
        URI uri = URI.create(baseUrl);
        if (!("http".equals(uri.getScheme()) || "https".equals(uri.getScheme())) || uri.getHost() == null
                || uri.getUserInfo() != null || uri.getQuery() != null || uri.getFragment() != null) {
            throw new IllegalArgumentException("RASA_BASE_URL must be an HTTP(S) service URL");
        }
        this.baseUrl = baseUrl.replaceAll("/+$", "");
        this.token = token;
        this.timeout = Duration.ofSeconds(Math.clamp(timeoutSeconds, 1, 120));
    }

    public Result send(String sender, String message) {
        try {
            HttpRequest request = HttpRequest.newBuilder(endpoint("/webhooks/rest/webhook"))
                    .timeout(timeout).header("Content-Type", "application/json").header("Accept", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(Map.of("sender", sender, "message", message))))
                    .build();
            var response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                throw unavailable();
            }
            List<ChatResponse.Message> messages = parse(response.body());
            String intent = readIntent(sender);
            boolean fallback = messages.isEmpty() || "nlu_fallback".equals(intent);
            if (messages.isEmpty()) {
                messages = List.of(new ChatResponse.Message(
                        "Mình chưa có câu trả lời phù hợp. Bạn thử hỏi về kiểu dáng, dịp mặc, màu sắc, size hoặc ngân sách nhé.",
                        null, List.of(), null));
            }
            return new Result(messages, intent, fallback);
        } catch (BusinessException exception) {
            throw exception;
        } catch (HttpTimeoutException exception) {
            throw new BusinessException(HttpStatus.GATEWAY_TIMEOUT, "CHAT_TIMEOUT", "Trợ lý phản hồi quá lâu. Bạn thử gửi lại nhé.");
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new BusinessException(HttpStatus.SERVICE_UNAVAILABLE, "CHAT_INTERRUPTED", "Cuộc trò chuyện bị gián đoạn. Bạn thử lại nhé.");
        } catch (IOException exception) {
            throw unavailable();
        }
    }

    private List<ChatResponse.Message> parse(String body) {
        try {
            if (body.length() > 800_000) throw invalidResponse();
            JsonNode root = json.readTree(body);
            if (root == null || !root.isArray() || root.size() > 30) throw invalidResponse();
            List<ChatResponse.Message> messages = new ArrayList<>();
            for (JsonNode item : root) {
                if (!item.isObject()) throw invalidResponse();
                String text = optionalText(item, "text", 12_000);
                String image = optionalText(item, "image", 4096);
                if (image != null && !safeMedia(image)) image = null;
                List<ChatResponse.Button> buttons = new ArrayList<>();
                JsonNode rawButtons = item.get("buttons");
                if (rawButtons != null && !rawButtons.isNull()) {
                    if (!rawButtons.isArray() || rawButtons.size() > 20) throw invalidResponse();
                    for (JsonNode button : rawButtons) {
                        String title = optionalText(button, "title", 100);
                        String payload = optionalText(button, "payload", 1000);
                        if (title == null || payload == null) throw invalidResponse();
                        buttons.add(new ChatResponse.Button(title, payload));
                    }
                }
                Map<String, Object> custom = null;
                JsonNode rawCustom = item.get("custom");
                if (rawCustom != null && !rawCustom.isNull()) {
                    if (!rawCustom.isObject()) throw invalidResponse();
                    custom = json.convertValue(rawCustom, new TypeReference<>() {});
                }
                if (text != null || image != null || !buttons.isEmpty() || custom != null) {
                    messages.add(new ChatResponse.Message(text, image, List.copyOf(buttons), custom));
                }
            }
            return List.copyOf(messages);
        } catch (BusinessException exception) {
            throw exception;
        } catch (Exception exception) {
            throw invalidResponse();
        }
    }

    private String readIntent(String sender) {
        // Tracker data is optional: do not fail or retry an already delivered message if it is unavailable.
        try {
            HttpRequest request = HttpRequest.newBuilder(endpoint("/conversations/" + sender + "/tracker?include_events=NONE"))
                    .timeout(Duration.ofSeconds(2)).GET().build();
            var response = http.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200 || response.body().length() > 100_000) return null;
            String intent = json.readTree(response.body()).path("latest_message").path("intent").path("name").asText("");
            return intent.matches("[A-Za-z0-9_]{1,100}") ? intent : null;
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            return null;
        } catch (Exception exception) {
            return null;
        }
    }

    private URI endpoint(String path) {
        String authentication = token.isBlank() ? "" : (path.contains("?") ? "&" : "?")
                + "token=" + URLEncoder.encode(token, StandardCharsets.UTF_8);
        return URI.create(baseUrl + path + authentication);
    }

    private static String optionalText(JsonNode node, String field, int maximum) {
        JsonNode value = node.get(field);
        if (value == null || value.isNull()) return null;
        if (!value.isTextual() || value.textValue().length() > maximum) throw invalidResponse();
        return value.textValue().isBlank() ? null : value.textValue();
    }

    private static boolean safeMedia(String value) {
        try {
            URI uri = URI.create(value);
            return ("http".equalsIgnoreCase(uri.getScheme()) || "https".equalsIgnoreCase(uri.getScheme()))
                    && uri.getHost() != null && uri.getUserInfo() == null;
        } catch (IllegalArgumentException exception) { return false; }
    }

    private static BusinessException unavailable() {
        return new BusinessException(HttpStatus.SERVICE_UNAVAILABLE, "CHAT_UNAVAILABLE", "Trợ lý chưa sẵn sàng. Bạn thử lại sau một chút nhé.");
    }

    private static BusinessException invalidResponse() {
        return new BusinessException(HttpStatus.BAD_GATEWAY, "CHAT_INVALID_RESPONSE", "Trợ lý trả phản hồi không hợp lệ. Bạn thử lại nhé.");
    }
}
