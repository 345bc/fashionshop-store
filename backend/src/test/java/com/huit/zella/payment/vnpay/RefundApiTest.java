package com.huit.zella.payment.vnpay;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.exception.GlobalExceptionHandler;
import com.huit.zella.orderreturn.*;
import org.junit.jupiter.api.*;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.method.annotation.AuthenticationPrincipalArgumentResolver;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.mock.web.MockServletContext;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.support.AnnotationConfigWebApplicationContext;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.*;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class RefundApiTest {
    private AnnotationConfigWebApplicationContext context;
    private MockMvc mvc;
    private VnPayRefundService refunds;
    @Configuration @EnableWebMvc @EnableWebSecurity @EnableMethodSecurity
    static class Config implements WebMvcConfigurer {
        @Bean VnPayRefundService refunds() { return mock(VnPayRefundService.class); }
        @Bean ReturnService returns() { return mock(ReturnService.class); }
        @Bean VnPayRefundController refundController(VnPayRefundService service) { return new VnPayRefundController(service); }
        @Bean ReturnController returnController(ReturnService service) { return new ReturnController(service); }
        @Bean GlobalExceptionHandler errors() { return new GlobalExceptionHandler(); }
        @Bean SecurityFilterChain security(HttpSecurity http) throws Exception {
            return http.authorizeHttpRequests(auth -> auth.anyRequest().authenticated())
                .exceptionHandling(errors -> errors.authenticationEntryPoint((request, response, cause) -> response.sendError(401)))
                .build();
        }
        @Override public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
            resolvers.add(new AuthenticationPrincipalArgumentResolver());
        }
    }
    @BeforeEach void setup() {
        context = new AnnotationConfigWebApplicationContext(); context.setServletContext(new MockServletContext());
        context.register(Config.class); context.refresh();
        refunds = context.getBean(VnPayRefundService.class);
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
    }
    @AfterEach void close() { context.close(); }
    @Test void rejectsAnonymousNonAdminAndMissingCsrf() throws Exception {
        String path = "/api/v1/order/1/vnpay-refund";
        mvc.perform(post(path).with(csrf()).contentType("application/json").content("{\"note\":\"Hoàn\"}")).andExpect(status().isUnauthorized());
        mvc.perform(post(path).with(user("warehouse").roles("WAREHOUSE")).with(csrf())
            .contentType("application/json").content("{\"note\":\"Hoàn\"}")).andExpect(status().isForbidden());
        mvc.perform(post(path).with(user("admin").roles("ADMIN"))
            .contentType("application/json").content("{\"note\":\"Hoàn\"}")).andExpect(status().isForbidden());
        verifyNoInteractions(refunds);
    }
    @Test void validatesRefundNoteIdAndMalformedJsonBeforeService() throws Exception {
        for (String body : List.of("{}", "{\"note\":\" \"}", "{\"note\":\"" + "x".repeat(401) + "\"}", "not-json")) {
            mvc.perform(post("/api/v1/order/1/vnpay-refund").with(user("admin").roles("ADMIN")).with(csrf())
                .contentType("application/json").content(body)).andExpect(status().isBadRequest());
        }
        mvc.perform(post("/api/v1/order/-1/vnpay-refund").with(user("admin").roles("ADMIN")).with(csrf())
            .contentType("application/json").content("{\"note\":\"Hoàn\"}")).andExpect(status().isBadRequest())
            .andExpect(jsonPath("code").value("VALIDATION_ERROR"));
        verifyNoInteractions(refunds);
    }
    @Test void validatesReturnPagingAndNestedNullItems() throws Exception {
        mvc.perform(get("/api/v1/order-return/management?page=-1").with(user("admin").roles("ADMIN")))
            .andExpect(status().isBadRequest());
        mvc.perform(get("/api/v1/order-return/management?size=51").with(user("admin").roles("ADMIN")))
            .andExpect(status().isBadRequest());
        mvc.perform(post("/api/v1/order-return").with(user("admin").roles("ADMIN")).with(csrf())
            .contentType("application/json").content("{\"orderId\":1,\"reason\":\"Trả hàng\",\"items\":[null]}"))
            .andExpect(status().isBadRequest());
        verifyNoInteractions(context.getBean(ReturnService.class));
    }
    @Test void forwardsAuthenticatedAdminIdentityAndReturnTarget() throws Exception {
        CurrentUser principal = new CurrentUser(9L, "admin@test.test", "admin", List.of("ROLE_ADMIN"));
        var authentication = new UsernamePasswordAuthenticationToken(principal, "N/A", List.of(new SimpleGrantedAuthority("ROLE_ADMIN")));
        mvc.perform(post("/api/v1/order-return/10/vnpay-refund").with(authentication(authentication)).with(csrf())
            .contentType("application/json").content("{\"note\":\"Hàng đã nhận\"}"))
            .andExpect(status().isOk());
        verify(refunds).submit(null, 10L, "Hàng đã nhận", 9L);
    }
}
