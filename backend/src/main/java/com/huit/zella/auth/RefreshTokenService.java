package com.huit.zella.auth;

import com.huit.zella.common.exception.BusinessException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseCookie;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.Base64;
import java.util.HexFormat;

@Service @Profile("jwt-auth")
public class RefreshTokenService {
    static final String COOKIE_NAME = "REFRESH_TOKEN";
    private static final Duration CONCURRENT_WINDOW = Duration.ofSeconds(10);
    private final RefreshSessionRepository sessions;
    private final UserRepository users;
    private final UserService userService;
    private final JwtAccessTokenService accessTokens;
    private final byte[] rotationKey;
    private final Duration ttl;
    private final boolean secure;
    private final SecureRandom random = new SecureRandom();

    public RefreshTokenService(RefreshSessionRepository sessions, UserRepository users, UserService userService,
            JwtAccessTokenService accessTokens, @Value("${app.auth.jwt.secret}") String secret,
            @Value("${app.auth.jwt.refresh-token-days:7}") long days,
            @Value("${app.auth.jwt.cookie-secure:false}") boolean secure) {
        if (days < 1 || days > 90) throw new IllegalArgumentException("Refresh token phải có hạn từ 1 đến 90 ngày");
        this.sessions = sessions; this.users = users; this.userService = userService; this.accessTokens = accessTokens;
        this.rotationKey = secret.getBytes(StandardCharsets.UTF_8); this.ttl = Duration.ofDays(days); this.secure = secure;
    }

    @Transactional
    public void issue(CurrentUser user, HttpServletRequest request, HttpServletResponse response) {
        revoke(request);
        byte[] bytes = new byte[32]; random.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        Instant now = Instant.now();
        RefreshSession session = new RefreshSession();
        session.setActiveRole(user.activeRole());
        session.setRoleSelectionRequired(user.roleSelectionRequired());
        session.setUser(users.getReferenceById(user.id())); session.setTokenHash(hash(token));
        session.setPasswordFingerprint(hash(session.getUser().getPasswordHash()));
        session.setCreatedAt(now); session.setRotatedAt(now); session.setExpiresAt(now.plus(ttl));
        sessions.saveAndFlush(session);
        accessTokens.writeLoginCookie(response, user, session.getId());
        writeCookie(response, token, ttl);
    }

    @Transactional(noRollbackFor = BusinessException.class)
    public CurrentUser refresh(HttpServletRequest request, HttpServletResponse response) {
        String token = readCookie(request);
        if (token == null || !token.matches("[A-Za-z0-9_-]{43}")) throw invalid(response);
        RefreshSession session = sessions.findForUpdate(hash(token)).orElseThrow(() -> invalid(response));
        Instant now = Instant.now();
        User user = session.getUser();
        if (session.getRevokedAt() != null || !session.getExpiresAt().isAfter(now)
                || !user.isActive() || !session.getPasswordFingerprint().equals(hash(user.getPasswordHash()))) {
            session.setRevokedAt(now); throw invalid(response);
        }
        boolean previous = hash(token).equals(session.getPreviousTokenHash());
        if (previous) {
            if (session.getRotatedAt().plus(CONCURRENT_WINDOW).isBefore(now)) {
                session.setRevokedAt(now); throw invalid(response);
            }
            token = successor(token);
            if (!hash(token).equals(session.getTokenHash())) {
                session.setRevokedAt(now); throw invalid(response);
            }
        } else if (!session.getRotatedAt().plus(CONCURRENT_WINDOW).isAfter(now)) {
            session.setPreviousTokenHash(session.getTokenHash());
            token = successor(token); session.setTokenHash(hash(token)); session.setRotatedAt(now);
        }
        CurrentUser current = userService.requireById(user.getId());
        if (!session.isRoleSelectionRequired() && (session.getActiveRole() == null || !current.roles().contains(session.getActiveRole()))) {
            session.setRevokedAt(now); throw invalid(response);
        }
        current = session.isRoleSelectionRequired() ? current.pendingRoleSelection() : current.withActiveRole(session.getActiveRole());
        accessTokens.writeLoginCookie(response, current, session.getId());
        writeCookie(response, token, Duration.between(now, session.getExpiresAt()));
        response.setHeader("Cache-Control", "no-store");
        return current;
    }

    @Transactional
    public void revoke(HttpServletRequest request) {
        Arrays.stream(request.getCookies()==null ? new Cookie[0] : request.getCookies())
                .filter(c -> JwtAccessTokenService.COOKIE_NAME.equals(c.getName())).findFirst().ifPresent(cookie -> {
                    try {
                        Number sid=accessTokens.decode(cookie.getValue()).getClaim("sid");
                        if(sid!=null) sessions.findById(sid.longValue()).ifPresent(s -> s.setRevokedAt(Instant.now()));
                    } catch(org.springframework.security.oauth2.jwt.JwtException ignored) { }
                });
        String token = readCookie(request);
        if (token != null && token.matches("[A-Za-z0-9_-]{43}")) {
            sessions.findForUpdate(hash(token)).ifPresent(session -> session.setRevokedAt(Instant.now()));
        }
    }

    public void clearCookie(HttpServletResponse response) { writeCookie(response, "", Duration.ZERO); }
    private BusinessException invalid(HttpServletResponse response) {
        accessTokens.clearLoginCookie(response); clearCookie(response);
        return new BusinessException(HttpStatus.UNAUTHORIZED, "REFRESH_INVALID", "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.");
    }
    private void writeCookie(HttpServletResponse response, String token, Duration age) {
        response.addHeader("Set-Cookie", ResponseCookie.from(COOKIE_NAME, token).httpOnly(true).secure(secure)
                .sameSite("Lax").path("/").maxAge(age).build().toString());
    }
    private String readCookie(HttpServletRequest request) {
        return Arrays.stream(request.getCookies() == null ? new Cookie[0] : request.getCookies())
                .filter(cookie -> COOKIE_NAME.equals(cookie.getName())).map(Cookie::getValue).findFirst().orElse(null);
    }
    static String hash(String token) {
        try { return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8))); }
        catch (java.security.NoSuchAlgorithmException exception) { throw new IllegalStateException(exception); }
    }
    private String successor(String token) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256"); mac.init(new SecretKeySpec(rotationKey, "HmacSHA256"));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(("refresh-rotation:" + token).getBytes(StandardCharsets.UTF_8)));
        } catch (java.security.GeneralSecurityException exception) { throw new IllegalStateException(exception); }
    }
}
