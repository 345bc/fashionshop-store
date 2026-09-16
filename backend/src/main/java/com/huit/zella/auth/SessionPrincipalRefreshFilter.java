package com.huit.zella.auth;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.web.filter.OncePerRequestFilter;
import com.huit.zella.common.exception.BusinessException;

import java.io.IOException;
import java.util.Set;

public class SessionPrincipalRefreshFilter extends OncePerRequestFilter {
    private static final Set<String> SKIPPED_API_PATHS = Set.of(
            "/api/v1/project-info",
            "/api/v1/auth/csrf",
            "/api/v1/auth/logout",
            "/api/v1/auth/mock-login"
    );

    private final UserService appUserService;
    private final HttpSessionSecurityContextRepository contextRepository =
            new HttpSessionSecurityContextRepository();

    public SessionPrincipalRefreshFilter(UserService appUserService) {
        this.appUserService = appUserService;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        return !path.startsWith("/api/") || SKIPPED_API_PATHS.contains(path);
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null
                || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken) {
            filterChain.doFilter(request, response);
            return;
        }

        try {
            CurrentUser refreshed = appUserService.requireByEmail(emailOf(authentication));
            var authorities = refreshed.roles().stream()
                    .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                    .toList();
            var replacement = UsernamePasswordAuthenticationToken.authenticated(refreshed, null, authorities);
            replacement.setDetails(authentication.getDetails());
            var context = SecurityContextHolder.getContext();
            context.setAuthentication(replacement);
            if (request.getSession(false) != null) {
                contextRepository.saveContext(context, request, response);
            }
            filterChain.doFilter(request, response);
        } catch (BusinessException exception) {
            if (request.getSession(false) != null) {
                request.getSession(false).invalidate();
            }
            throw new AccessDeniedException(exception.getMessage(), exception);
        }
    }

    private String emailOf(Authentication authentication) {
        if (authentication.getPrincipal() instanceof CurrentUser currentUser) {
            return currentUser.email();
        }
//        if (authentication.getPrincipal() instanceof OidcUser oidcUser) {
//            return UserService.oidcEmail(oidcUser);
//        }
        return authentication.getName();
    }
}
