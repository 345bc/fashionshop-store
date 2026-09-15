package com.huit.zella.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.ObjectPostProcessor;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.client.oidc.userinfo.OidcUserService;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.access.intercept.AuthorizationFilter;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;
import org.springframework.security.web.csrf.CsrfFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import com.huit.zella.auth.*;

import java.util.List;

import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {
    private static final String[] PUBLIC_GET = {
            "/api/health", "/api/project-info", "/api/auth/csrf",
            "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html"
    };

    @Bean
    @Profile("oidc & !mock-auth & !jwt-auth")
    SecurityFilterChain oidcSecurityFilterChain(
            HttpSecurity http,
            OidcUserService oidcUserService,
            UserService userService,
            ApiSecurityErrorHandler apiSecurityErrorHandler,
            @Value("${app.auth.frontend-success-url:http://localhost:5173/auth/callback}") String successUrl,
            @Value("${app.auth.frontend-failure-url:http://localhost:5173/auth/callback?error=oidc}") String failureUrl
    ) throws Exception {
        configureCookieSecurity(http, apiSecurityErrorHandler)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, PUBLIC_GET).permitAll()
                        .requestMatchers("/oauth2/**", "/login/**").permitAll()
                        .anyRequest().authenticated())
                .exceptionHandling(errors -> errors
                        .authenticationEntryPoint(apiSecurityErrorHandler)
                        .accessDeniedHandler(apiSecurityErrorHandler))
                .oauth2Login(oauth -> oauth
                        .userInfoEndpoint(userInfo -> userInfo.oidcUserService(oidcUserService))
                        .defaultSuccessUrl(successUrl, true)
                        .failureUrl(failureUrl))
                .addFilterBefore(new SessionPrincipalRefreshFilter(userService), AuthorizationFilter.class);
        return http.build();
    }

    @Bean
    @Profile("mock-auth & !oidc & !jwt-auth")
    SecurityFilterChain mockSecurityFilterChain(
            HttpSecurity http,
            UserService userService,
            ApiSecurityErrorHandler apiSecurityErrorHandler
    ) throws Exception {
        configureCookieSecurity(http, apiSecurityErrorHandler)
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, PUBLIC_GET).permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/auth/mock-login").permitAll()
                        .anyRequest().authenticated())
                .exceptionHandling(errors -> errors
                        .authenticationEntryPoint(apiSecurityErrorHandler)
                        .accessDeniedHandler(apiSecurityErrorHandler))
                .addFilterBefore(new SessionPrincipalRefreshFilter(userService), AuthorizationFilter.class);
        return http.build();
    }

    @Bean
    @Profile("jwt-auth & !oidc & !mock-auth")
    SecurityFilterChain jwtSecurityFilterChain(
            HttpSecurity http,
            JwtAccessTokenService jwtAccessTokenService,
            UserService userService,
            ApiSecurityErrorHandler apiSecurityErrorHandler
    ) throws Exception {
        return configureCookieSecurity(http, apiSecurityErrorHandler)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, PUBLIC_GET).permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/login").permitAll()
                        .anyRequest().authenticated())
                .exceptionHandling(errors -> errors
                        .authenticationEntryPoint(apiSecurityErrorHandler)
                        .accessDeniedHandler(apiSecurityErrorHandler))
                .addFilterBefore(new JwtCookieAuthenticationFilter(jwtAccessTokenService, userService), AuthorizationFilter.class)
                .build();
    }

    @Bean
    @Profile("!oidc & !mock-auth & !jwt-auth")
    SecurityFilterChain lockedSecurityFilterChain(
            HttpSecurity http,
            ApiSecurityErrorHandler apiSecurityErrorHandler
    ) throws Exception {
        return configureCookieSecurity(http, apiSecurityErrorHandler)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, PUBLIC_GET).permitAll()
                        .anyRequest().denyAll())
                .exceptionHandling(errors -> errors
                        .authenticationEntryPoint(apiSecurityErrorHandler)
                        .accessDeniedHandler(apiSecurityErrorHandler))
                .build();
    }

    private HttpSecurity configureCookieSecurity(
            HttpSecurity http,
            ApiSecurityErrorHandler apiSecurityErrorHandler
    ) throws Exception {
        CookieCsrfTokenRepository csrf = CookieCsrfTokenRepository.withHttpOnlyFalse();
        csrf.setCookiePath("/");
        return http
                .csrf(config -> config
                        .ignoringRequestMatchers("/api/v1/auth/login", "/api/auth/mock-login")
                        .csrfTokenRepository(csrf)
                        .withObjectPostProcessor(new ObjectPostProcessor<CsrfFilter>() {
                            @Override
                            public <O extends CsrfFilter> O postProcess(O filter) {
                                filter.setAccessDeniedHandler(apiSecurityErrorHandler);
                                return filter;
                            }
                        }))
                .cors(cors -> {})
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.IF_REQUIRED));
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    @Profile("oidc")
    OidcUserService oidcUserServiceDelegate() {
        return new OidcUserService();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origin}") String allowedOrigin
    ) {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of(allowedOrigin));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-XSRF-TOKEN"));
        config.setExposedHeaders(List.of("Content-Disposition"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }

}
