package com.huit.zella.review;

import com.huit.zella.category.Category;
import com.huit.zella.product.Product;
import com.huit.zella.order.Order;
import com.huit.zella.order.OrderItem;
import com.huit.zella.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.*;
import org.springframework.aop.framework.ProxyFactory;
import org.springframework.validation.beanvalidation.MethodValidationInterceptor;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.Optional;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.access.AccessDeniedException;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class AdminReviewTest {
    @Configuration @EnableMethodSecurity
    static class SecurityTestConfig {
        @Bean AdminReviewService reviewService() { return mock(AdminReviewService.class); }
        @Bean AdminReviewController reviewController(AdminReviewService service) { return new AdminReviewController(service); }
    }

    @Test void onlyAdminAndCustomerSupportCanAccessReviews() {
        try (var context = new AnnotationConfigApplicationContext(SecurityTestConfig.class)) {
            var controller = context.getBean(AdminReviewController.class);
            for (String role : new String[]{"USER", "SALES", "WAREHOUSE", "MARKETING"}) {
                SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
                        "tester", "", java.util.List.of(new SimpleGrantedAuthority("ROLE_" + role))));
                assertThrows(AccessDeniedException.class, () -> controller.get(1));
                assertThrows(AccessDeniedException.class, () -> controller.reply(1, new ReviewReplyRequest("reply"), () -> "tester"));
                assertThrows(AccessDeniedException.class, () -> controller.moderate(1, new ReviewModerationRequest(true, "spam"), () -> "tester"));
            }
            for (String role : new String[]{"ADMIN", "CUSTOMER_SUPPORT"}) {
                SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
                        "tester", "", java.util.List.of(new SimpleGrantedAuthority("ROLE_" + role))));
                assertDoesNotThrow(() -> controller.get(1));
            }
        } finally {
            SecurityContextHolder.clearContext();
        }
    }
    ProductReviewRepository repository;
    AdminReviewService service;
    MockMvc mvc;

    @BeforeEach void setup() {
        repository = mock(ProductReviewRepository.class);
        service = new AdminReviewService(repository);
        var factory = new ProxyFactory(new AdminReviewController(service));
        factory.setProxyTargetClass(true);
        factory.addAdvice(new MethodValidationInterceptor());
        mvc = MockMvcBuilders.standaloneSetup(factory.getProxy())
                .setControllerAdvice(new GlobalExceptionHandler()).build();
    }

    @Test void invalidBodiesNeverReachPersistence() throws Exception {
        for (String body : new String[]{"{}", "{\"text\":\"   \"}", "{\"text\":\"" + "x".repeat(1001) + "\"}", "{"}) {
            mvc.perform(put("/api/v1/admin/reviews/1/reply").principal(() -> "support")
                    .contentType("application/json").content(body)).andExpect(status().isBadRequest());
        }
        for (String body : new String[]{"{}", "{\"hidden\":true,\"reason\":\" \"}",
                "{\"reason\":\"spam\"}", "{\"hidden\":true,\"reason\":\"" + "x".repeat(501) + "\"}"}) {
            mvc.perform(put("/api/v1/admin/reviews/1/visibility").principal(() -> "support")
                    .contentType("application/json").content(body)).andExpect(status().isBadRequest());
        }
        verifyNoInteractions(repository);
    }

    @Test void invalidIdsAndPaginationReturn400() throws Exception {
        for (String path : new String[]{"/0", "/-1", "/abc", "?page=-1", "?size=0", "?size=101", "?page=abc"}) {
            mvc.perform(get("/api/v1/admin/reviews" + path)).andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        }
        verifyNoInteractions(repository);
    }

    @Test void missingReviewReturns404() throws Exception {
        when(repository.findById(99L)).thenReturn(Optional.empty());
        mvc.perform(get("/api/v1/admin/reviews/99")).andExpect(status().isNotFound());
    }

    @Test void replyAndModerationPreserveCustomerContentAndAuditActor() {
        var r = review();
        when(repository.findForUpdate(1L)).thenReturn(Optional.of(r));
        when(repository.save(r)).thenReturn(r);
        var reply = service.reply(1, new ReviewReplyRequest(" Cảm ơn bạn "), "support@example.test");
        assertEquals("Cảm ơn bạn", reply.adminReply());
        assertNotNull(reply.repliedAt());
        var hidden = service.moderate(1, new ReviewModerationRequest(true, " Thông tin cá nhân "), "admin");
        assertTrue(hidden.hidden());
        assertEquals("Không hài lòng", hidden.comment());
        assertEquals(1, hidden.rating());
        assertEquals("support@example.test", hidden.history().getFirst().actor());
        assertEquals("Thông tin cá nhân", hidden.history().getLast().note());
        service.moderate(1, new ReviewModerationRequest(true, "Lặp lại"), "admin");
        assertEquals(2, r.getHistory().size());
        var visible = service.moderate(1, new ReviewModerationRequest(false, "Đã kiểm tra"), "admin");
        assertFalse(visible.hidden());
        assertEquals(3, visible.history().size());
        assertEquals("Cảm ơn bạn", visible.adminReply());
    }

    ProductReview review() {
        var c = new Category(); c.setId(1L); c.setName("Áo");
        var p = new Product(); p.setId(1L); p.setName("Áo sơ mi"); p.setCategory(c);
        var o = new Order(); o.setId(1L); o.setCode("ORD-1"); o.setRecipientName("Khách");
        var i = new OrderItem(); i.setId(1L); i.setSku("SKU-1");
        var r = new ProductReview(); r.setId(1L); r.setProduct(p); r.setOrder(o); r.setOrderItem(i);
        r.setRating(1); r.setComment("Không hài lòng");
        return r;
    }
}
