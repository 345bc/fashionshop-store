package com.huit.zella.productimage;

import com.huit.zella.common.exception.BusinessException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.DeleteObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.io.InputStream;
import java.util.UUID;

@Component
public class ProductImageFileStorage {
    private final S3Client s3Client;
    private final String bucket;
    private final long maxBytes;
    private final String publicUrl;

    public ProductImageFileStorage(
            S3Client s3Client,
            @Value("${cloudflare.r2.bucket}") String bucket,
            @Value("${app.storage.max-bytes}") long maxBytes,
            @Value("${cloudflare.r2.public-url}") String publicUrl
    ) {
        this.s3Client = s3Client;
        this.bucket = bucket;
        this.maxBytes = maxBytes;
        this.publicUrl = publicUrl.replaceAll("/+$", "");
    }

    public StoredImage store(MultipartFile file) {
        return store(file, "product-images");
    }

    public StoredImage storeVariant(MultipartFile file) {
        return store(file, "variant-images");
    }

    public StoredImage storeSizeGuide(MultipartFile file) {
        return store(file, "size-guide-images");
    }

    private StoredImage store(MultipartFile file, String folder) {
        if (file == null || file.isEmpty()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "IMAGE_REQUIRED", "Vui lòng chọn ảnh");
        }
        if (file.getSize() > maxBytes) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "IMAGE_TOO_LARGE", "Ảnh vượt quá dung lượng cho phép");
        }

        try {
            String extension;
            try (InputStream input = file.getInputStream()) {
                extension = detectExtension(input.readNBytes(12));
            }
            if (extension == null) {
                throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_IMAGE", "Chỉ hỗ trợ ảnh JPG, PNG, GIF hoặc WebP");
            }

            String fileName = UUID.randomUUID() + "." + extension;
            String key = folder + "/" + fileName;
            s3Client.putObject(
                    PutObjectRequest.builder()
                            .bucket(bucket)
                            .key(key)
                            .contentType(contentType(extension))
                            .build(),
                    RequestBody.fromBytes(file.getBytes())
            );
            return new StoredImage(fileName, publicUrl + "/" + key);
        } catch (IOException error) {
            throw new BusinessException(HttpStatus.INTERNAL_SERVER_ERROR, "IMAGE_STORAGE_FAILED", "Không thể đọc ảnh");
        }
    }

    public void delete(String fileName) {
        delete(fileName, "product-images");
    }

    public void deleteVariant(String fileName) {
        delete(fileName, "variant-images");
    }

    public void deleteSizeGuide(String fileName) {
        delete(fileName, "size-guide-images");
    }

    private void delete(String fileName, String folder) {
        if (!fileName.matches("[0-9a-f-]{36}\\.(jpg|png|gif|webp)")) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_IMAGE_NAME", "Tên ảnh không hợp lệ");
        }
        s3Client.deleteObject(DeleteObjectRequest.builder()
                .bucket(bucket)
                .key(folder + "/" + fileName)
                .build());
    }

    public String publicUrlPrefix() {
        return publicUrl + "/product-images/";
    }

    public String variantPublicUrlPrefix() {
        return publicUrl + "/variant-images/";
    }

    public String sizeGuidePublicUrlPrefix() {
        return publicUrl + "/size-guide-images/";
    }

    private String contentType(String extension) {
        return switch (extension) {
            case "jpg" -> "image/jpeg";
            case "png" -> "image/png";
            case "gif" -> "image/gif";
            default -> "image/webp";
        };
    }

    private String detectExtension(byte[] header) {
        if (header.length >= 3 && (header[0] & 0xff) == 0xff && (header[1] & 0xff) == 0xd8 && (header[2] & 0xff) == 0xff) return "jpg";
        if (header.length >= 8 && (header[0] & 0xff) == 0x89 && header[1] == 'P' && header[2] == 'N' && header[3] == 'G'
                && header[4] == 13 && header[5] == 10 && (header[6] & 0xff) == 0x1a && header[7] == 10) return "png";
        if (header.length >= 6 && header[0] == 'G' && header[1] == 'I' && header[2] == 'F'
                && header[3] == '8' && (header[4] == '7' || header[4] == '9') && header[5] == 'a') return "gif";
        if (header.length >= 12 && header[0] == 'R' && header[1] == 'I' && header[2] == 'F' && header[3] == 'F'
                && header[8] == 'W' && header[9] == 'E' && header[10] == 'B' && header[11] == 'P') return "webp";
        return null;
    }

    public record StoredImage(String fileName, String url) {}
}
