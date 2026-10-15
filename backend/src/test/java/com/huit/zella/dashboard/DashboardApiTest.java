package com.huit.zella.dashboard;

import com.huit.zella.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.*;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.access.AccessDeniedException;
import java.time.LocalDate;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class DashboardApiTest {
    DashboardService service;
    MockMvc mvc;
    @BeforeEach void setup() {
        service=mock(DashboardService.class);
        mvc=MockMvcBuilders.standaloneSetup(new DashboardController(service))
                .setControllerAdvice(new GlobalExceptionHandler()).build();
    }
    @Test void invalidQueryReturns400BeforeQueryingDatabase() throws Exception {
        for(String query:List.of("", "?start=wrong&end=2001-01-02", "?start=2001-01-02&end=2001-01-01",
                "?start=2001-01-01&end=2003-01-01", "?start=2999-01-01&end=2999-01-02",
                "?start=2001-01-01&end=2001-01-02&page=-1", "?start=2001-01-01&end=2001-01-02&size=101",
                "?start=2001-01-01&end=2001-01-02&size=0", "?start=2001-01-01&end=2001-01-02&section=invalid",
                "?start=2001-01-01&end=2001-01-02&status=invalid", "?start=2001-01-01&end=2001-01-02&page=wrong")) {
            mvc.perform(get("/api/v1/dashboard"+query)).andExpect(status().isBadRequest());
        }
        mvc.perform(get("/api/v1/dashboard").param("start","2001-01-01").param("end","2001-01-02").param("q","x".repeat(201)))
                .andExpect(status().isBadRequest());
        verifyNoInteractions(service);
    }
    @Test void defaultsAreValidatedAndBound() throws Exception {
        when(service.report(any())).thenReturn(Map.of("test",true));
        mvc.perform(get("/api/v1/dashboard").param("start","2001-01-01").param("end","2001-01-02"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.test").value(true));
        verify(service).report(argThat(q -> q.page()==0&&q.size()==10&&q.section()==DashboardQuery.Section.overview));
    }
    @Configuration @EnableMethodSecurity
    static class SecurityConfig {
        @Bean DashboardService service() {return mock(DashboardService.class);}
        @Bean DashboardController controller(DashboardService service) {return new DashboardController(service);}
    }
    @Test void onlyAdminCanReadFinancialReports() {
        try(var context=new AnnotationConfigApplicationContext(SecurityConfig.class)) {
            var controller=context.getBean(DashboardController.class);
            var query=new DashboardQuery(LocalDate.of(2001,1,1),LocalDate.of(2001,1,2),null,null,null,null,null,null);
            for(String role:List.of("USER","SALES","CUSTOMER_SUPPORT","WAREHOUSE","MARKETING")) {
                SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
                        "tester","",List.of(new SimpleGrantedAuthority("ROLE_"+role))));
                assertThrows(AccessDeniedException.class,()->controller.get(query));
            }
            SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
                    "admin","",List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))));
            assertDoesNotThrow(()->controller.get(query));
        } finally {SecurityContextHolder.clearContext();}
    }
}
