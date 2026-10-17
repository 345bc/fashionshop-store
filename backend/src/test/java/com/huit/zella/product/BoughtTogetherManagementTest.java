package com.huit.zella.product;

import com.huit.zella.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.math.BigDecimal;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class BoughtTogetherManagementTest {
    @Test void miningPagesExposeMultiProductRulesAndPublicApiBindsFullContext() throws Exception {
        var settings=mock(BoughtTogetherSettingsService.class);
        var service=mock(BoughtTogetherService.class);
        var rule=new FpGrowth.Rule(List.of(1L),List.of(2L,3L,4L),2,0.5,0.8,1.6);
        when(service.associationRules(0,20)).thenReturn(new BoughtTogetherService.MiningPage<>(List.of(rule),0,20,1,1));
        when(service.itemsets(0,20,4)).thenReturn(new BoughtTogetherService.MiningPage<>(
            List.of(new BoughtTogetherService.FrequentItemset(List.of(1L,2L,3L,4L),2,0.5)),0,20,1,1));
        when(service.get(List.of(1L,2L),24)).thenReturn(new BoughtTogetherService.Result(java.time.Instant.EPOCH,4,List.of()));
        var mvc=MockMvcBuilders.standaloneSetup(new BoughtTogetherManagementController(settings,service),new BoughtTogetherController(service)).build();
        mvc.perform(get("/api/v1/admin/bought-together/rules"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.content[0].antecedent.length()").value(1))
            .andExpect(jsonPath("$.data.content[0].consequent[2]").value(4));
        mvc.perform(get("/api/v1/admin/bought-together/itemsets").param("level","4"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.content[0].items[3]").value(4));
        mvc.perform(get("/api/v1/product/bought-together").param("productIds","1,2"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.totalTransactions").value(4));
        verify(service).get(List.of(1L,2L),24);
    }
    static final String PAYLOAD="""
        {"windowDays":180,"minSupport":0.01,"minConfidence":0.1,"minLift":1,"maxRecommendations":8,"enabled":true}
        """;
    static BoughtTogetherSettingsService.Settings config() {
        return new BoughtTogetherSettingsService.Settings(180,new BigDecimal("0.01"),new BigDecimal("0.1"),BigDecimal.ONE,8,true);
    }
    @Test void rejectsInvalidThresholdsBeforeSaving() throws Exception {
        var settings=mock(BoughtTogetherSettingsService.class);
        var service=mock(BoughtTogetherService.class);
        var mvc=MockMvcBuilders.standaloneSetup(new BoughtTogetherManagementController(settings,service))
            .setControllerAdvice(new GlobalExceptionHandler()).build();
        for(String replacement:List.of("\"windowDays\":0","\"windowDays\":366","\"minSupport\":0","\"minSupport\":1.1",
            "\"minSupport\":0.0000001",
            "\"minConfidence\":-0.1","\"minConfidence\":1.1","\"minLift\":-1","\"minLift\":101",
            "\"maxRecommendations\":0","\"maxRecommendations\":25","\"enabled\":null")) {
            String key=replacement.substring(0,replacement.indexOf(':'));
            String invalid=PAYLOAD.replaceAll(java.util.regex.Pattern.quote(key)+":([^,}]+)",java.util.regex.Matcher.quoteReplacement(replacement));
            mvc.perform(put("/api/v1/admin/bought-together/settings").contentType("application/json").content(invalid))
                .andExpect(status().isBadRequest());
        }
        verifyNoInteractions(settings,service);
        when(settings.save(any())).thenReturn(config());
        mvc.perform(put("/api/v1/admin/bought-together/settings").contentType("application/json").content(PAYLOAD))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.minSupport").value(0.01));
    }
    @Test void savesAllSettingsInDatabase() {
        var jdbc=mock(JdbcTemplate.class);
        var service=new BoughtTogetherSettingsService(jdbc);
        when(jdbc.update(anyString(),eq(180),eq(new BigDecimal("0.01")),eq(new BigDecimal("0.1")),eq(BigDecimal.ONE),eq(8),eq(true))).thenReturn(1);
        assertEquals(config(),service.save(config()));
        verify(jdbc).update(anyString(),eq(180),eq(new BigDecimal("0.01")),eq(new BigDecimal("0.1")),eq(BigDecimal.ONE),eq(8),eq(true));
    }
    @Configuration @EnableMethodSecurity
    static class Security {
        @Bean BoughtTogetherService service() { return mock(BoughtTogetherService.class); }
        @Bean BoughtTogetherSettingsService settings() { return mock(BoughtTogetherSettingsService.class); }
        @Bean BoughtTogetherManagementController controller(BoughtTogetherSettingsService settings,BoughtTogetherService service) {
            return new BoughtTogetherManagementController(settings,service);
        }
    }
    @Test void onlyAdminAndMarketingCanManageRecommendations() {
        try(var context=new AnnotationConfigApplicationContext(Security.class)) {
            var controller=context.getBean(BoughtTogetherManagementController.class);
            for(String role:List.of("USER","SALES","WAREHOUSE","CUSTOMER_SUPPORT")) {
                authenticate(role);
                assertThrows(AccessDeniedException.class,controller::settings);
                assertThrows(AccessDeniedException.class,()->controller.save(config()));
                assertThrows(AccessDeniedException.class,controller::status);
                assertThrows(AccessDeniedException.class,()->controller.itemsets(0,20,0));
                assertThrows(AccessDeniedException.class,()->controller.rules(0,20));
                assertThrows(AccessDeniedException.class,()->controller.preview(List.of(1L,2L)));
                assertThrows(AccessDeniedException.class,controller::rebuild);
                assertThrows(AccessDeniedException.class,()->controller.preview(1L));
            }
            for(String role:List.of("ADMIN","MARKETING")) {
                authenticate(role);
                assertDoesNotThrow(controller::settings);
                assertDoesNotThrow(()->controller.save(config()));
                assertDoesNotThrow(controller::status);
                assertDoesNotThrow(()->controller.itemsets(0,20,0));
                assertDoesNotThrow(()->controller.rules(0,20));
                assertDoesNotThrow(()->controller.preview(List.of(1L,2L)));
                assertDoesNotThrow(controller::rebuild);
                assertDoesNotThrow(()->controller.preview(1L));
            }
        } finally { SecurityContextHolder.clearContext(); }
    }
    private void authenticate(String role) {
        SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated("tester","",List.of(new SimpleGrantedAuthority("ROLE_"+role))));
    }
}
