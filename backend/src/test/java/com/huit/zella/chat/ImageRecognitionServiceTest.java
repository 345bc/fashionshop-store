package com.huit.zella.chat;

import com.huit.zella.common.exception.BusinessException;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicInteger;
import static org.junit.jupiter.api.Assertions.*;

class ImageRecognitionServiceTest {
    private static final String IMAGE = "data:image/png;base64,iVBORw0KGgo=";

    @Test void validatesSizeFormatAndSignatureBeforeCallingModel() {
        assertThrows(BusinessException.class, () -> ImageRecognitionService.validateImage("data:image/png;base64,YmFk"));
        assertThrows(BusinessException.class, () -> ImageRecognitionService.validateImage("data:image/jpeg;base64,iVBORw0KGgo="));
        assertThrows(BusinessException.class, () -> ImageRecognitionService.validateImage("https://example.com/test.png"));
        assertThrows(BusinessException.class, () -> ImageRecognitionService.validateImage("x".repeat(7_000_001)));
        assertDoesNotThrow(() -> ImageRecognitionService.validateImage(IMAGE));
    }

    @Test void callsPredictionWithoutLoginOrCookieAndReturnsBothModelResults() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        AtomicInteger predictions = new AtomicInteger();
        server.createContext("/api/predict", exchange -> {
            predictions.incrementAndGet();
            assertTrue(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8).contains(IMAGE));
            assertNull(exchange.getRequestHeaders().getFirst("Cookie"));
            byte[] payload = """
                {"width":640,"height":480,"detections":[{"label":"AoThun","confidence":0.95,
                  "box":[1,2,100,200],"colors":[{"label":"black","confidence":0.9}]}]}
                """.getBytes(StandardCharsets.UTF_8);
            exchange.sendResponseHeaders(200, payload.length);
            exchange.getResponseBody().write(payload); exchange.close();
        });
        server.start();
        try {
            var service = new ImageRecognitionService("http://127.0.0.1:" + server.getAddress().getPort());
            var result = service.predict(IMAGE);
            assertEquals("AoThun", result.detections().getFirst().label());
            assertEquals("black", result.detections().getFirst().colors().getFirst().label());
            assertEquals(1, predictions.get());
            service.predict(IMAGE);
            assertEquals(2, predictions.get());
        } finally { server.stop(0); }
    }

}
