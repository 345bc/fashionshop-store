package com.huit.zella.auth;

import com.huit.zella.common.api.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.ObjectProvider;
import lombok.experimental.FieldDefaults;
import org.springframework.http.ResponseCookie;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.logout.SecurityContextLogoutHandler;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {
    UserService userService;
    private final boolean secureJwtCookie;
    private final ObjectProvider<RefreshTokenService> refreshTokens;

    public AuthController(
            UserService userService,
            @Value("${app.auth.jwt.cookie-secure:false}") boolean secureJwtCookie,
            ObjectProvider<RefreshTokenService> refreshTokens
    ) {
        this.userService = userService;
        this.secureJwtCookie = secureJwtCookie;
        this.refreshTokens = refreshTokens;
    }

    @GetMapping("/csrf")
    ApiResponse<Map<String, String>> csrf(CsrfToken token) {
        return ApiResponse.success(Map.of(
                "headerName", token.getHeaderName(),
                "parameterName", token.getParameterName(),
                "token", token.getToken()
        ));
    }

    @GetMapping("/me")
    ApiResponse<CurrentUser> me(Authentication authentication) {
        return ApiResponse.success(userService.current(authentication));
    }

    @PostMapping("/logout")
    ApiResponse<Void> logout(
            HttpServletRequest request,
            HttpServletResponse response,
            Authentication authentication
    ) {
        RefreshTokenService service = refreshTokens.getIfAvailable();
        if (service != null) { service.revoke(request); service.clearCookie(response); }
        new SecurityContextLogoutHandler().logout(request, response, authentication);
        response.addHeader("Set-Cookie", ResponseCookie.from(JwtAccessTokenService.COOKIE_NAME, "")
                .httpOnly(true)
                .secure(secureJwtCookie)
                .sameSite("Lax")
                .path("/")
                .maxAge(Duration.ZERO)
                .build()
                .toString());
        return ApiResponse.success(null, "Đã đăng xuất");
    }
}
