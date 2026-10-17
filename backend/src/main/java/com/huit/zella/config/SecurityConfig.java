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
            "/api/health", "/api/project-info", "/api/v1/auth/csrf",
            "/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html",
            "/api/v1/product/**", "/api/v1/product-image/files/*",
            "/api/v1/category/**", "/api/v1/checkout/orders/*", "/api/v1/payment/vnpay/ipn",
            "/api/v1/size/**","/api/v1/color/**", "/api/v1/posts/**",
    };


    @Bean
    @Profile("jwt-auth")
    SecurityFilterChain jwtSecurityFilterChain(
            HttpSecurity http,
            JwtAccessTokenService jwtAccessTokenService,
            UserService userService,
            RefreshSessionRepository sessions,
            ApiSecurityErrorHandler apiSecurityErrorHandler
    ) throws Exception {
        return configureCookieSecurity(http, apiSecurityErrorHandler)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers(HttpMethod.GET, PUBLIC_GET).permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/v1/auth/login", "/api/v1/auth/admin/login", "/api/v1/auth/register", "/api/v1/auth/refresh", "/api/v1/auth/logout",
                                "/api/v1/checkout/orders", "/api/v1/checkout/orders/lookup", "/api/v1/checkout/orders/voucher", "/api/v1/checkout/orders/quote", "/api/v1/checkout/orders/*/cancel", "/api/v1/cart/quote",
                                "/api/v1/checkout/orders/*/payment", "/api/v1/checkout/orders/*/payment/verify", "/api/v1/posts/*/view-session", "/api/v1/posts/*/views").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/v1/supplier/**", "/api/v1/sizeguide/**", "/api/v1/product-variant/**", "/api/v1/product-image/**", "/api/v1/variant-image/**")
                            .hasAnyRole("ADMIN", "SALES", "WAREHOUSE", "MARKETING")
                        .requestMatchers("/api/v1/role", "/api/v1/role/**", "/api/v1/user/**", "/api/v1/staff/**", "/api/v1/dashboard/**", "/api/v1/settings/**").hasRole("ADMIN")
                        .requestMatchers("/api/v1/inventory/**", "/api/v1/goods-receipt/**", "/api/v1/supplier/**").hasAnyRole("ADMIN", "WAREHOUSE")
                        .requestMatchers("/api/v1/admin/home/**").hasAnyRole("ADMIN", "MARKETING")
                        .requestMatchers("/api/v1/admin/bought-together/**").hasAnyRole("ADMIN", "MARKETING")
                        .requestMatchers("/api/v1/admin/posts/**").hasAnyRole("ADMIN", "MARKETING")
                        .requestMatchers("/api/v1/campaigns/**").hasAnyRole("ADMIN", "MARKETING")
                        .requestMatchers(HttpMethod.GET, "/api/v1/order/**").hasAnyRole("ADMIN", "SALES", "CUSTOMER_SUPPORT", "WAREHOUSE")
                        .requestMatchers("/api/v1/order/**").hasAnyRole("ADMIN", "SALES", "CUSTOMER_SUPPORT")
                        .requestMatchers("/api/v1/order-return/**").hasAnyRole("ADMIN", "CUSTOMER_SUPPORT", "WAREHOUSE")
                        .anyRequest().authenticated())
                .exceptionHandling(errors -> errors
                        .authenticationEntryPoint(apiSecurityErrorHandler)
                        .accessDeniedHandler(apiSecurityErrorHandler))
                .addFilterBefore(new JwtCookieAuthenticationFilter(jwtAccessTokenService, userService, sessions), AuthorizationFilter.class)
                .build();
    }

    private HttpSecurity configureCookieSecurity(
            HttpSecurity http,
            ApiSecurityErrorHandler apiSecurityErrorHandler
    ) throws Exception {
        CookieCsrfTokenRepository csrf = CookieCsrfTokenRepository.withHttpOnlyFalse();
        csrf.setCookiePath("/");
        org.springframework.security.web.csrf.CsrfTokenRequestAttributeHandler requestHandler = new org.springframework.security.web.csrf.CsrfTokenRequestAttributeHandler();
        // set the name of the attribute the CsrfToken will be populated on
        requestHandler.setCsrfRequestAttributeName(null);
        return http
                .csrf(config -> config
                        .ignoringRequestMatchers("/api/v1/auth/login", "/api/v1/auth/admin/login", "/api/v1/auth/register", "/api/auth/mock-login")
                        .csrfTokenRepository(csrf)
                        .csrfTokenRequestHandler(requestHandler)
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
        config.setAllowedHeaders(List.of("Authorization", "Content-Type", "X-XSRF-TOKEN", "X-Checkout-Token", "X-Requested-With"));
        config.setExposedHeaders(List.of("Content-Disposition"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }

}
