package com.huit.zella.config;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.auth.JwtAccessTokenService;
import com.huit.zella.auth.OAuth2AuthenticationSuccessHandler;
import com.huit.zella.auth.RefreshSessionRepository;
import com.huit.zella.auth.UserService;
import com.huit.zella.inventory.CreateInventoryAdjustmentRequest;
import com.huit.zella.inventory.InventoryController;
import com.huit.zella.inventory.InventoryService;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.core.env.MapPropertySource;
import org.springframework.data.domain.Page;
import org.springframework.mock.web.MockServletContext;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.client.registration.ClientRegistrationRepository;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.support.AnnotationConfigWebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.authentication;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AdminAccessTest {
    @Configuration
    @EnableWebMvc
    @EnableWebSecurity
    @Import({SecurityConfig.class, ApiSecurityErrorHandler.class, TestEndpoints.class, InventoryController.class})
    static class Config {
        @Bean JwtAccessTokenService tokens() { return mock(JwtAccessTokenService.class); }
        @Bean UserService users() { return mock(UserService.class); }
        @Bean RefreshSessionRepository sessions() { return mock(RefreshSessionRepository.class); }
        @Bean OAuth2AuthenticationSuccessHandler oauth() { return mock(OAuth2AuthenticationSuccessHandler.class); }
        @Bean ClientRegistrationRepository clients() { return mock(ClientRegistrationRepository.class); }
        @Bean InventoryService inventory() {
            var inventory = mock(InventoryService.class);
            when(inventory.list(any(), any(), any(), any())).thenReturn(Page.empty());
            return inventory;
        }
    }

    @RestController
    static class TestEndpoints {
        @RequestMapping("/api/v1/**")
        String endpoint() { return "ok"; }

        @PostMapping("/api/v1/order-return/1/approve")
        @PreAuthorize("hasRole('ADMIN')")
        public String privilegedAction() { return "ok"; }
    }

    @Test
    void activeAdminRoleIsLimitedToManagementAndReports() throws Exception {
        try (var context = new AnnotationConfigWebApplicationContext()) {
            context.setServletContext(new MockServletContext());
            context.getEnvironment().setActiveProfiles("jwt-auth");
            context.getEnvironment().getPropertySources().addFirst(new MapPropertySource(
                    "test", Map.of("app.cors.allowed-origin", "http://localhost:3000")));
            context.register(Config.class);
            context.refresh();
            MockMvc mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
            var admin = user("admin").roles("ADMIN");
            var superadmin = user("superadmin").roles("SUPERADMIN");

            for (String path : List.of("customers", "user", "staff", "dashboard", "auth/me")) {
                mvc.perform(get("/api/v1/" + path).with(admin)).andExpect(status().isOk());
            }
            for (String path : List.of("role", "auth/select-role")) {
                mvc.perform(post("/api/v1/" + path).with(admin).with(csrf())).andExpect(status().isOk());
            }
            for (String path : List.of("order", "inventory", "campaigns", "product", "me/orders")) {
                mvc.perform(get("/api/v1/" + path).with(admin)).andExpect(status().isForbidden());
                mvc.perform(get("/api/v1/" + path).with(superadmin)).andExpect(status().isOk());
            }
            for (String path : List.of("checkout/orders", "order/1/vnpay-refund", "order-return/1/approve")) {
                mvc.perform(post("/api/v1/" + path).with(admin).with(csrf())).andExpect(status().isForbidden());
                mvc.perform(post("/api/v1/" + path).with(superadmin).with(csrf())).andExpect(status().isOk());
            }
            mvc.perform(post("/api/v1/inventory/adjustments").with(superadmin)).andExpect(status().isForbidden());
            for (String role : List.of("ADMIN", "SALES", "CUSTOMER_SUPPORT", "MARKETING", "USER")) {
                mvc.perform(post("/api/v1/inventory/adjustments").with(user("tester").roles(role))
                        .with(csrf())).andExpect(status().isForbidden());
            }
            var adjustment = new CreateInventoryAdjustmentRequest("Kiểm kê",
                    List.of(new CreateInventoryAdjustmentRequest.Item(1L, 5, 6)));
            for (String role : List.of("WAREHOUSE", "SUPERADMIN")) {
                var actor = new CurrentUser(42L, "tester@example.test", "tester", List.of(role));
                var session = UsernamePasswordAuthenticationToken.authenticated(actor, null,
                        List.of(new SimpleGrantedAuthority("ROLE_" + role)));
                mvc.perform(post("/api/v1/inventory/adjustments").with(authentication(session)).with(csrf())
                        .contentType("application/json")
                        .content("""
                                {"reason":"Kiểm kê","items":[{"variantId":1,"expectedQuantity":5,"countedQuantity":6}]}
                                """)).andExpect(status().isOk());
            }
            verify(context.getBean(InventoryService.class), times(2)).adjust(adjustment, 42L);
            mvc.perform(get("/api/v1/order").with(user("sales").roles("SALES"))).andExpect(status().isOk());
            mvc.perform(get("/api/v1/inventory").with(user("warehouse").roles("WAREHOUSE"))).andExpect(status().isOk());
            mvc.perform(get("/api/v1/dashboard").with(user("sales").roles("SALES"))).andExpect(status().isForbidden());
            mvc.perform(get("/api/v1/product")).andExpect(status().isOk());
        }
    }
}
