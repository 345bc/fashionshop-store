package com.huit.zella.auth;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.mail.EmailQueue;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.time.Instant;
import java.util.*;

@Service
public class PasswordResetService {
    private final UserRepository users;
    private final PasswordResetRepository resets;
    private final PasswordEncoder encoder;
    private final EmailQueue emails;
    private final String frontend;
    private final SecureRandom random = new SecureRandom();

    public PasswordResetService(UserRepository users, PasswordResetRepository resets,
            PasswordEncoder encoder, EmailQueue emails,
            @Value("${app.frontend-url:http://localhost:3000}") String frontend) {
        this.users = users; this.resets = resets;
        this.encoder = encoder; this.emails = emails;
        java.net.URI uri = java.net.URI.create(frontend);
        if (!Set.of("http", "https").contains(uri.getScheme()) || uri.getHost() == null
                || uri.getRawQuery() != null || uri.getRawFragment() != null || uri.getUserInfo() != null)
            throw new IllegalArgumentException("FRONTEND_URL must be an absolute HTTP(S) URL");
        this.frontend = frontend.replaceAll("/+$", "");
    }

    @Transactional
    public void request(String email) {
        if (!emails.enabled()) throw new BusinessException(HttpStatus.SERVICE_UNAVAILABLE,
                "EMAIL_UNAVAILABLE", "Chức năng email chưa được cấu hình. Vui lòng thử lại sau.");
        User user = users.lockByEmail(email.trim().toLowerCase(Locale.ROOT)).orElse(null);
        if (user == null || !user.isActive()) return;
        Instant now = Instant.now();
        PasswordReset reset = resets.findById(user.getId()).orElseGet(PasswordReset::new);
        if (reset.getCreatedAt() != null && reset.getCreatedAt().plusSeconds(60).isAfter(now)) return;
        byte[] bytes = new byte[32]; random.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        reset.setUserId(user.getId()); reset.setTokenHash(hash(token)); reset.setAuthVersion(user.getAuthVersion());
        reset.setCreatedAt(now); reset.setExpiresAt(now.plusSeconds(900));
        resets.save(reset);
        // Fragment keeps the secret out of HTTP access logs and referrer headers.
        emails.enqueue(user.getEmail(), "ZELLA - Đặt lại mật khẩu",
                "Bạn đã yêu cầu đặt lại mật khẩu ZELLA.\n\nMở liên kết sau (có hiệu lực 15 phút, chỉ dùng một lần):\n"
                        + frontend + "/reset-password#token=" + token
                        + "\n\nNếu bạn không yêu cầu, hãy bỏ qua email này.", reset.getExpiresAt());
    }

    @Transactional
    public void reset(String token, String password) {
        if (password.getBytes(StandardCharsets.UTF_8).length > 72)
            throw new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_PASSWORD", "Mật khẩu không được vượt quá 72 byte UTF-8.");
        Long userId = resets.findUserId(hash(token)).orElseThrow(this::invalid);
        // Serialize requests and redemptions on the same account, including concurrent submissions.
        User user = users.lockById(userId).orElseThrow(this::invalid);
        PasswordReset reset = resets.findById(userId).orElseThrow(this::invalid);
        if (!user.isActive() || !reset.getExpiresAt().isAfter(Instant.now())
                || reset.getAuthVersion() != user.getAuthVersion() || !reset.getTokenHash().equals(hash(token)))
            throw invalid();
        user.setPasswordHash(encoder.encode(password));
        user.setAuthVersion(user.getAuthVersion() + 1);
        // authVersion invalidates access tokens immediately; password fingerprint invalidates refresh tokens.
        // Avoid locking refresh sessions here: refresh already locks session before reading user.
        resets.delete(reset);
    }

    static String hash(String token) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8))); }
        catch (NoSuchAlgorithmException failure) { throw new IllegalStateException(failure); }
    }

    private BusinessException invalid() {
        return new BusinessException(HttpStatus.BAD_REQUEST, "INVALID_RESET_TOKEN", "Liên kết không hợp lệ hoặc đã hết hạn. Vui lòng yêu cầu liên kết mới.");
    }
}
