package com.huit.zella.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.huit.zella.common.exception.BusinessException;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;
import static org.junit.jupiter.api.Assertions.*;

class RasaClientTest {
    HttpServer server;
    String body = "[]";
    int status = 200;
    String trackerIntent = "ask_style";
    AtomicReference<String> sent = new AtomicReference<>();
    AtomicReference<String> cookie = new AtomicReference<>();
    AtomicReference<String> query = new AtomicReference<>();

    @BeforeEach void setup() throws Exception {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/webhooks/rest/webhook", exchange -> {
            sent.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
            cookie.set(exchange.getRequestHeaders().getFirst("Cookie"));
            query.set(exchange.getRequestURI().getRawQuery());
            byte[] bytes = body.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(status, bytes.length);
            exchange.getResponseBody().write(bytes); exchange.close();
        });
        server.createContext("/conversations/", exchange -> {
            byte[] bytes = ("{\"latest_message\":{\"intent\":{\"name\":\"" + trackerIntent + "\"}}}").getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, bytes.length);
            exchange.getResponseBody().write(bytes); exchange.close();
        });
        server.start();
    }

    @AfterEach void cleanup() { server.stop(0); }

    RasaClient client() { return new RasaClient("http://127.0.0.1:" + server.getAddress().getPort(), "service-secret", 5); }

    @Test void preservesAdviceButtonsCatalogAndChartsWithoutForwardingStoreCookies() throws Exception {
        body = """
                [{"recipient_id":"private-sender","text":"Tư vấn kiểu dáng","buttons":[{"title":"Tìm áo","payload":"tìm áo thun"}]},
                 {"image":"https://images.example/size.png"},
                 {"custom":{"type":"products","products":[{"id":"12","slug":"ao-thun","price":195000}]}},
                 {"custom":{"type":"size_guide","product":"Áo","sizes":["M"],"chartUrl":"https://images.example/size.png"}}]
                """;
        var result = client().send("zella-7-test", "Tư vấn giúp mình");
        assertEquals(4, result.messages().size());
        assertEquals("tìm áo thun", result.messages().getFirst().buttons().getFirst().payload());
        assertEquals("products", result.messages().get(2).custom().get("type"));
        assertEquals("size_guide", result.messages().get(3).custom().get("type"));
        assertEquals("ask_style", result.intent());
        assertFalse(result.fallback());
        assertEquals("zella-7-test", new ObjectMapper().readTree(sent.get()).path("sender").asText());
        assertNull(cookie.get());
        assertEquals("token=service-secret", query.get());
    }

    @Test void emptyReplyProducesExplicitFallback() {
        var result = client().send("test", "?");
        assertTrue(result.fallback());
        assertEquals(1, result.messages().size());
        assertTrue(result.messages().getFirst().text().contains("chưa có câu trả lời"));
    }

    @Test void tracksNluFallbackWithoutChangingBotAdvice() {
        body = "[{\"text\":\"Bạn muốn tư vấn gì?\"}]";
        trackerIntent = "nlu_fallback";
        assertTrue(client().send("test", "không rõ").fallback());
    }

    @Test void invalidJsonAndMalformedMessagesAreGatewayErrors() {
        for (String invalid : new String[]{"broken", "{}", "[null]", "[{\"text\":123}]", "[{\"buttons\":[{}]}]", "[{\"custom\":[]}]"}) {
            body = invalid;
            var error = assertThrows(BusinessException.class, () -> client().send("test", "hi"));
            assertEquals("CHAT_INVALID_RESPONSE", error.getCode());
            assertEquals(502, error.getStatus().value());
        }
    }

    @Test void upstreamFailuresDoNotLeakModelDiagnostics() {
        status = 500; body = "private traceback with service-secret";
        var error = assertThrows(BusinessException.class, () -> client().send("test", "hi"));
        assertEquals("CHAT_UNAVAILABLE", error.getCode());
        assertFalse(error.getMessage().contains("private"));
    }

    @Test void rejectsExecutableMediaAndNeverExposesRecipientIdentifiers() {
        body = "[{\"recipient_id\":\"private\",\"text\":\"Bảng size\",\"image\":\"javascript:alert(1)\"}]";
        var result = client().send("test", "size");
        assertNull(result.messages().getFirst().image());
    }
}
