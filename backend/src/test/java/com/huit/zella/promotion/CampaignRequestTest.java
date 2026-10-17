package com.huit.zella.promotion;

import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CampaignRequestTest {
    @Test void absentOrNullRedeemableDefaultsToFalseWhileExplicitTrueIsPreserved() throws Exception {
        for (String field : new String[]{"", ",\"redeemable\":null", ",\"redeemable\":false", ",\"redeemable\":true"}) {
            var service = mock(CampaignManagementService.class);
            var mvc = MockMvcBuilders.standaloneSetup(new CampaignController(service)).build();
            String body = """
                    {"name":"Ưu đãi sản phẩm mới","description":"Khám phá thiết kế mới",
                    "startsAt":"2026-10-10T14:19:00Z","endsAt":"2099-01-01T00:00:00Z",
                    "enabled":true,"discountPercent":5,"targetMode":"NEW_PRODUCTS","productIds":[]%s}
                    """.formatted(field);
            mvc.perform(post("/api/v1/campaigns/promotion").contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isOk());
            verify(service).save(eq("promotion"), isNull(), argThat(r ->
                    Boolean.valueOf(field.endsWith("true")).equals(r.redeemable()) && r.enabled()));
        }
    }
}
