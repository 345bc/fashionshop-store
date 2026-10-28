package com.huit.zella.auth;

import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.security.web.authentication.SimpleUrlAuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Component
@Slf4j
public class OAuth2AuthenticationSuccessHandler extends SimpleUrlAuthenticationSuccessHandler {

    private final UserService userService;
    private final RefreshTokenService refreshTokenService;
    private final String frontendUrl;

    public OAuth2AuthenticationSuccessHandler(
            UserService userService,
            RefreshTokenService refreshTokenService,
            @Value("${app.frontend-url:http://localhost:3000}") String frontendUrl
    ) {
        this.userService = userService;
        this.refreshTokenService = refreshTokenService;
        this.frontendUrl = frontendUrl.replaceAll("/$", "");
    }

    @Override
    public void onAuthenticationSuccess(
            HttpServletRequest request,
            HttpServletResponse response,
            Authentication authentication
    ) throws IOException, ServletException {
        try {
            Object principal = authentication.getPrincipal();
            String email = null;
            String name = null;

            if (principal instanceof OidcUser oidcUser) {
                email = oidcUser.getEmail();
                name = oidcUser.getFullName();
                if (name == null || name.isBlank()) {
                    name = oidcUser.getAttribute("name");
                }
            } else if (principal instanceof OAuth2User oauth2User) {
                email = oauth2User.getAttribute("email");
                name = oauth2User.getAttribute("name");
            }

            if (email == null || email.isBlank()) {
                log.error("Google OAuth2 authentication failed: email is missing");
                getRedirectStrategy().sendRedirect(request, response, frontendUrl + "/login?error=email_missing");
                return;
            }

            CurrentUser user = userService.processOAuthPostLogin(email, name);

            // Issue JWT and refresh token cookies
            refreshTokenService.issue(user, request, response);

            clearAuthenticationAttributes(request);
            getRedirectStrategy().sendRedirect(request, response, frontendUrl + "/login?oauth2=success");
        } catch (Exception ex) {
            log.error("Error handling Google OAuth2 authentication success", ex);
            getRedirectStrategy().sendRedirect(request, response, frontendUrl + "/login?error=oauth2_failed");
        }
    }
}
