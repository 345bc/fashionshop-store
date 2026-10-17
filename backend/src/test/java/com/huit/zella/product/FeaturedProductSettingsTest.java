package com.huit.zella.product;
import com.huit.zella.common.exception.*;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class FeaturedProductSettingsTest {
    @Test void invalidTotalCannotBeSavedAndValidConfigurationIsPersisted() {
        var jdbc=mock(JdbcTemplate.class);var service=new FeaturedProductSettingsService(jdbc);
        assertThrows(BusinessException.class,()->service.save(new FeaturedProductSettingsService.Request("Title",null,30,60,60,true)));
        verifyNoInteractions(jdbc);
        when(jdbc.update(anyString(),eq("Title"),eq("Description"),eq(7),eq(70),eq(30),eq(true))).thenReturn(1);
        var result=service.save(new FeaturedProductSettingsService.Request(" Title "," Description ",7,70,30,true));
        assertEquals("Title",result.title());assertEquals(7,result.windowDays());assertEquals(70,result.purchaseWeight());
        verify(jdbc).update(anyString(),eq("Title"),eq("Description"),eq(7),eq(70),eq(30),eq(true));
    }
    @Test void invalidWindowWeightsAndMissingVisibilityAreRejectedBeforePersistence() throws Exception {
        var service=mock(FeaturedProductSettingsService.class);
        var mvc=MockMvcBuilders.standaloneSetup(new FeaturedProductSettingsController(service)).setControllerAdvice(new GlobalExceptionHandler()).build();
        for(var change:new String[]{"\"windowDays\":0","\"windowDays\":366","\"purchaseWeight\":101","\"reviewWeight\":-1","\"isDisplay\":null","\"title\":\" \""}) {
            String payload="{\"title\":\"Featured\",\"windowDays\":30,\"purchaseWeight\":60,\"reviewWeight\":40,\"isDisplay\":true}";
            var key=change.substring(0,change.indexOf(':'));
            payload=payload.replaceAll(java.util.regex.Pattern.quote(key)+":([^,}]+)",java.util.regex.Matcher.quoteReplacement(change));
            mvc.perform(put("/api/v1/admin/home/featured-products").contentType("application/json").content(payload)).andExpect(status().isBadRequest());
        }
        verifyNoInteractions(service);
        when(service.save(any())).thenReturn(new FeaturedProductSettingsService.Settings("Featured",null,30,60,40,true));
        mvc.perform(put("/api/v1/admin/home/featured-products").contentType("application/json").content("{\"title\":\"Featured\",\"windowDays\":30,\"purchaseWeight\":60,\"reviewWeight\":40,\"isDisplay\":true}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.windowDays").value(30));
    }
}
