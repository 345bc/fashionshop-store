package com.huit.zella.chat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.huit.zella.common.exception.BusinessException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Base64;
import java.util.Map;
import java.util.List;
import java.util.concurrent.Semaphore;

@Service
public class ImageRecognitionService {
    public record Color(String label, double confidence) {
    }

    public record Detection(String label, double confidence, List<Double> box, List<Color> colors) {
    }

    public record Result(int width, int height, List<Detection> detections) {
    }

    private final String baseUrl;
    private final ObjectMapper json = new ObjectMapper();
    private final HttpClient http = HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();
    private final Semaphore capacity = new Semaphore(1);

    public ImageRecognitionService(
            @Value("${AI_MODEL_BASE_URL}") String baseUrl) {
        this.baseUrl = baseUrl.replaceAll("/+$", "");
    }

    public Result predict(String image) {
        validateImage(image);
        if (!capacity.tryAcquire())
            throw failure(HttpStatus.TOO_MANY_REQUESTS, "AI_BUSY", "Model đang xử lý ảnh khác. Vui lòng thử lại sau.");
        try {
            HttpResponse<String> response = request("/api/predict", Map.of("image", image, "confidence", 0.40));
            if (response.statusCode() == 422 || response.statusCode() == 400)
                throw failure(HttpStatus.UNPROCESSABLE_ENTITY, "AI_INVALID_IMAGE", "Model không đọc được ảnh. Vui lòng chọn ảnh quần áo rõ hơn.");
            if (response.statusCode() != 200)
                throw failure(HttpStatus.SERVICE_UNAVAILABLE, "AI_UNAVAILABLE", "Model chưa khởi động. Vui lòng thử lại sau.");

            JsonNode result = json.readTree(response.body());
            if (result == null || !result.path("detections").isArray())
                throw failure(HttpStatus.BAD_GATEWAY, "AI_INVALID_RESPONSE", "Dịch vụ nhận diện trả dữ liệu không hợp lệ.");

            Result typed = json.treeToValue(result, Result.class);
            if (typed.width() <= 0 || typed.height() <= 0 || typed.detections().stream().anyMatch(item ->
                    item.label() == null || item.colors() == null || !Double.isFinite(item.confidence()) ||
                            item.confidence() < 0 || item.confidence() > 1 || item.colors().stream().anyMatch(color ->
                            color.label() == null || !Double.isFinite(color.confidence()) || color.confidence() < 0 || color.confidence() > 1)))
                throw failure(HttpStatus.BAD_GATEWAY, "AI_INVALID_RESPONSE", "Dịch vụ nhận diện trả dữ liệu không hợp lệ.");
            return typed;
        } catch (BusinessException e) {
            throw e;
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw failure(HttpStatus.SERVICE_UNAVAILABLE, "AI_INTERRUPTED", "Quá trình nhận diện bị gián đoạn.");
        } catch (java.net.http.HttpTimeoutException e) {
            throw failure(HttpStatus.GATEWAY_TIMEOUT, "AI_TIMEOUT", "Nhận diện mất quá lâu. Vui lòng thử lại.");
        } catch (Exception e) {
            throw failure(HttpStatus.SERVICE_UNAVAILABLE, "AI_CONNECTION_FAILED", "Không kết nối được dịch vụ nhận diện ảnh.");
        } finally {
            capacity.release();
        }
    }

    private HttpResponse<String> request(String path, Object body) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder(URI.create(baseUrl + path))
                .timeout(Duration.ofSeconds(100)).header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(json.writeValueAsString(body)));
        return http.send(builder.build(), HttpResponse.BodyHandlers.ofString());
    }

    static void validateImage(String image) {
        if (image == null || image.length() > 7_000_000 ||
                !(image.startsWith("data:image/png;base64,") || image.startsWith("data:image/jpeg;base64,")))
            throw failure(HttpStatus.BAD_REQUEST, "INVALID_IMAGE", "Chỉ hỗ trợ ảnh PNG hoặc JPG tối đa 5 MB.");

        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(image.substring(image.indexOf(',') + 1));
        } catch (IllegalArgumentException e) {
            throw failure(HttpStatus.BAD_REQUEST, "INVALID_IMAGE", "Ảnh base64 không hợp lệ.");
        }
        boolean png = bytes.length >= 8 && bytes[0] == (byte) 137 && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71
                && bytes[4] == 13 && bytes[5] == 10 && bytes[6] == 26 && bytes[7] == 10;
        boolean jpg = bytes.length >= 3 && bytes[0] == (byte) 255 && bytes[1] == (byte) 216 && bytes[2] == (byte) 255;
        if (bytes.length > 5 * 1024 * 1024 || (image.startsWith("data:image/png") ? !png : !jpg))
            throw failure(HttpStatus.BAD_REQUEST, "INVALID_IMAGE", "Chỉ hỗ trợ ảnh PNG hoặc JPG hợp lệ, tối đa 5 MB.");
    }

    private static BusinessException failure(HttpStatus status, String code, String message) {
        return new BusinessException(status, code, message);
    }
}
