package com.huit.zella.auth;

import com.nimbusds.jose.jwk.source.ImmutableSecret;
import com.nimbusds.jose.proc.SecurityContext;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.http.ResponseCookie;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.*;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;

@Service
@Profile("jwt-auth")
public class JwtAccessTokenService {
    static final String COOKIE_NAME = "ACCESS_TOKEN";

    private final SecretKey secretKey;
    private final JwtEncoder encoder;
    private final JwtDecoder decoder;
    private final String issuer;
    private final Duration tokenTtl;
    private final boolean secureCookie;

    JwtAccessTokenService(
            @Value("${app.auth.jwt.secret}") String secret,
            @Value("${app.auth.jwt.issuer:fresher-core}") String issuer,
            @Value("${app.auth.jwt.access-token-minutes:30}") long tokenMinutes,
            @Value("${app.auth.jwt.cookie-secure:false}") boolean secureCookie
    ) {
        byte[] secretBytes = secret.getBytes(StandardCharsets.UTF_8);
        if (secretBytes.length < 32) {
            throw new IllegalStateException("JWT_SECRET phải có ít nhất 32 ký tự");
        }
        this.secretKey = new SecretKeySpec(secretBytes, "HmacSHA256");
        this.encoder = new NimbusJwtEncoder(new ImmutableSecret<SecurityContext>(secretKey));
        this.decoder = NimbusJwtDecoder.withSecretKey(secretKey)
                .macAlgorithm(MacAlgorithm.HS256)
                .build();
        this.issuer = issuer;
        this.tokenTtl = Duration.ofMinutes(tokenMinutes);
        this.secureCookie = secureCookie;
    }

    void writeLoginCookie(HttpServletResponse response, CurrentUser user) {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer(issuer)
                .subject(user.email())
                .issuedAt(now)
                .expiresAt(now.plus(tokenTtl))
                .claim("roles", user.roles())
                .build();
        String token = encoder.encode(JwtEncoderParameters.from(
                org.springframework.security.oauth2.jwt.JwsHeader.with(MacAlgorithm.HS256).build(), claims
        )).getTokenValue();
        response.addHeader("Set-Cookie", cookie(token, tokenTtl).toString());
    }

    Jwt decode(String token) {
        return decoder.decode(token);
    }

    void clearLoginCookie(HttpServletResponse response) {
        response.addHeader("Set-Cookie", cookie("", Duration.ZERO).toString());
    }

    private ResponseCookie cookie(String value, Duration maxAge) {
        return ResponseCookie.from(COOKIE_NAME, value)
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite("Lax")
                .path("/")
                .maxAge(maxAge)
                .build();
    }
}
