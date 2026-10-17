package com.huit.zella.promotion;

import com.huit.zella.common.exception.GlobalExceptionHandler;
import com.huit.zella.productimage.ProductImageFileStorage;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.*;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class CampaignImageApiTest {
    @Test void multipartCoverUploadReturnsPublicCloudUrl() throws Exception {
        var storage = mock(ProductImageFileStorage.class);
        var file = new MockMultipartFile("file", "cover.png", "image/png", new byte[]{1,2,3});
        when(storage.storeCampaign(any())).thenReturn(new ProductImageFileStorage.StoredImage("cover.png", "https://cloud.example/campaign-images/cover.png"));
        var mvc = MockMvcBuilders.standaloneSetup(new CampaignImageController(storage)).setControllerAdvice(new GlobalExceptionHandler()).build();
        mvc.perform(multipart("/api/v1/campaigns/images").file(file))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.url").value("https://cloud.example/campaign-images/cover.png"));
        verify(storage).storeCampaign(any());
        mvc.perform(multipart("/api/v1/campaigns/images")).andExpect(status().isBadRequest());
        verifyNoMoreInteractions(storage);
    }

    @Configuration @EnableMethodSecurity static class Security {
        @Bean ProductImageFileStorage storage() { return mock(ProductImageFileStorage.class); }
        @Bean CampaignImageController controller(ProductImageFileStorage storage) { return new CampaignImageController(storage); }
    }

    @Test void onlyAdminAndMarketingCanUploadCovers() {
        try (var context = new AnnotationConfigApplicationContext(Security.class)) {
            var controller = context.getBean(CampaignImageController.class);
            var storage = context.getBean(ProductImageFileStorage.class);
            var file = new MockMultipartFile("file", new byte[]{1});
            for (String role : List.of("USER", "SALES", "WAREHOUSE", "CUSTOMER_SUPPORT")) {
                authenticate(role);
                assertThrows(AccessDeniedException.class, () -> controller.upload(file));
            }
            verifyNoInteractions(storage);
            when(storage.storeCampaign(file)).thenReturn(new ProductImageFileStorage.StoredImage("image.png", "https://cloud.example/image.png"));
            for (String role : List.of("ADMIN", "MARKETING")) {
                authenticate(role);
                assertEquals("https://cloud.example/image.png", controller.upload(file).data().url());
            }
        } finally { SecurityContextHolder.clearContext(); }
    }
    private void authenticate(String role) {
        SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
                "tester", "", List.of(new SimpleGrantedAuthority("ROLE_" + role))));
    }
}
