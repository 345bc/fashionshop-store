package com.huit.zella.auth;

import com.huit.zella.common.exception.BusinessException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.JwtException;
import org.springframework.web.filter.OncePerRequestFilter;
import com.huit.zella.common.exception.BusinessException;

import java.io.IOException;
import java.util.Arrays;
import java.util.Optional;
import java.util.Set;

public class JwtCookieAuthenticationFilter extends OncePerRequestFilter {
    private static final Set<String> SKIPPED_API_PATHS = Set.of(
            "/api/health", "/api/project-info", "/api/auth/csrf", "/api/v1/auth/login"
    );

    private final JwtAccessTokenService tokenService;
    private final UserService appUserService;

    public JwtCookieAuthenticationFilter(JwtAccessTokenService tokenService, UserService appUserService) {
        this.tokenService = tokenService;
        this.appUserService = appUserService;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return !request.getRequestURI().startsWith("/api/")
                || SKIPPED_API_PATHS.contains(request.getRequestURI());
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        Optional<String> token = Arrays.stream(Optional.ofNullable(request.getCookies()).orElse(new Cookie[0]))
                .filter(cookie -> JwtAccessTokenService.COOKIE_NAME.equals(cookie.getName()))
                .map(Cookie::getValue)
                .findFirst();

        if (token.isEmpty()) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            CurrentUser user = appUserService.requireByEmail(tokenService.decode(token.get()).getSubject());
            var authorities = user.roles().stream()
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                    .toList();
            SecurityContextHolder.getContext().setAuthentication(
                    UsernamePasswordAuthenticationToken.authenticated(user, null, authorities)
            );
        } catch (JwtException exception) {
            SecurityContextHolder.clearContext();
            tokenService.clearLoginCookie(response);
        } catch (BusinessException exception) {
            SecurityContextHolder.clearContext();
            tokenService.clearLoginCookie(response);
            throw new AccessDeniedException(exception.getMessage(), exception);
        }
        filterChain.doFilter(request, response);
    }
}
