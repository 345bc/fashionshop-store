package com.huit.zella.promotion;
import com.huit.zella.common.exception.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.access.AccessDeniedException;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class HomeAppearanceTest {
    @Test void savingVisibilityAndAssetsDoesNotChangeAutomaticPricingOrManagedCampaigns() {
        var jdbc=mock(JdbcTemplate.class);var service=new HomeAppearanceService(jdbc);
        when(jdbc.update(anyString(),eq("Title"),eq("Description"),eq("https://example.com/banner.jpg"),eq(false))).thenReturn(1);
        var result=service.save(new HomeAppearanceService.Request(" Title "," Description ","https://example.com/banner.jpg",false));
        assertFalse(result.isDisplay());assertEquals("Title",result.title());
        verify(jdbc).update(eq("update new_product_showcase set title=?,description=?,image_url=?,is_display=? where id=1"),eq("Title"),eq("Description"),eq("https://example.com/banner.jpg"),eq(false));
        verifyNoMoreInteractions(jdbc);
        assertThrows(BusinessException.class,()->service.save(new HomeAppearanceService.Request("Title",null,null,true)));
    }
    @Test void validatesFieldsAndRejectsMissingBooleanRatherThanDeserializingPrimitiveNull() throws Exception {
        var service=mock(HomeAppearanceService.class);
        var mvc=MockMvcBuilders.standaloneSetup(new HomeAppearanceController(service)).setControllerAdvice(new GlobalExceptionHandler()).build();
        for(var payload:List.of(
            "{\"title\":\" \",\"isDisplay\":false}",
            "{\"title\":\"Title\",\"isDisplay\":null}",
            "{\"title\":\"Title\",\"isDisplay\":true,\"imageUrl\":\"javascript:alert(1)\"}"))
            mvc.perform(put("/api/v1/admin/home/new-products").contentType("application/json").content(payload)).andExpect(status().isBadRequest());
        verifyNoInteractions(service);
        when(service.save(any())).thenReturn(new HomeAppearanceService.Settings("New",null,"https://example.com/banner.jpg",true));
        mvc.perform(put("/api/v1/admin/home/new-products").contentType("application/json")
            .content("{\"title\":\"New\",\"description\":null,\"imageUrl\":\"https://example.com/banner.jpg\",\"isDisplay\":true}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.isDisplay").value(true));
    }
    @Configuration @EnableMethodSecurity static class Security {
        @Bean HomeAppearanceService service(){return mock(HomeAppearanceService.class);}
        @Bean HomeAppearanceController controller(HomeAppearanceService s){return new HomeAppearanceController(s);}
    }
    @Test void onlyAdminAndMarketingCanManageHomeAppearance() {
        try(var context=new AnnotationConfigApplicationContext(Security.class)) {
            var controller=context.getBean(HomeAppearanceController.class);var service=context.getBean(HomeAppearanceService.class);
            for(var role:List.of("USER","SALES","WAREHOUSE","CUSTOMER_SUPPORT")) {
                authenticate(role);assertThrows(AccessDeniedException.class,controller::get);
                assertThrows(AccessDeniedException.class,()->controller.save(new HomeAppearanceService.Request("New",null,null,false)));
            }
            verifyNoInteractions(service);
            when(service.get()).thenReturn(new HomeAppearanceService.Settings("New",null,null,false));
            for(var role:List.of("ADMIN","MARKETING")){authenticate(role);assertEquals("New",controller.get().data().title());}
        } finally { SecurityContextHolder.clearContext(); }
    }
    void authenticate(String role) {
        SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated("tester","",List.of(new SimpleGrantedAuthority("ROLE_"+role))));
    }
}
