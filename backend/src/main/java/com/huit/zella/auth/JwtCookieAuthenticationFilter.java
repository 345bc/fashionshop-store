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

import java.io.IOException;
import java.util.Arrays;
import java.util.Optional;
import java.util.Set;

public class JwtCookieAuthenticationFilter extends OncePerRequestFilter {
    private static final Set<String> SKIPPED_API_PATHS = Set.of(
            "/api/health", "/api/project-info", "/api/v1/auth/csrf", "/api/v1/auth/login", "/api/v1/auth/admin/login", "/api/v1/auth/refresh", "/api/v1/auth/logout"
    );

    private final RefreshSessionRepository sessions;
    private final JwtAccessTokenService tokenService;
    private final UserService appUserService;

    public JwtCookieAuthenticationFilter(JwtAccessTokenService tokenService, UserService appUserService, RefreshSessionRepository sessions) {
        this.sessions = sessions;
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
            var jwt = tokenService.decode(token.get());
            boolean pending = Boolean.TRUE.equals(jwt.getClaim("roleSelectionRequired"));
            if (!pending && jwt.getClaimAsString("activeRole") == null) throw new JwtException("Active role required");
            Number userId = jwt.getClaim("uid");
            Number sid = jwt.getClaim("sid");
            if(sid==null || userId==null) throw new JwtException("Session required");
            var session=sessions.findById(sid.longValue()).orElseThrow(()->new JwtException("Session not found"));
            if(session.getRevokedAt()!=null || !session.getExpiresAt().isAfter(java.time.Instant.now())
                    || !session.getUser().getId().equals(userId.longValue())
                    || session.isRoleSelectionRequired()!=pending
                    || !java.util.Objects.equals(session.getActiveRole(),jwt.getClaimAsString("activeRole"))) throw new JwtException("Session revoked");
            Number version = jwt.getClaim("authVersion");
            CurrentUser user = appUserService.requireForAccessToken(userId.longValue(), version);
            user = pending ? user.pendingRoleSelection() : user.withActiveRole(jwt.getClaimAsString("activeRole"));
            if (pending && !Set.of("/api/v1/auth/me", "/api/v1/auth/select-role").contains(request.getRequestURI())) {
                response.setStatus(403); response.setContentType("application/json;charset=UTF-8");
                response.getWriter().write("{\"status\":403,\"code\":\"ROLE_SELECTION_REQUIRED\",\"message\":\"Vui lòng chọn vai trò làm việc trước khi thao tác\"}");
                return;
            }
            var authorities = (pending ? java.util.List.<String>of() : java.util.List.of(user.activeRole())).stream()
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
