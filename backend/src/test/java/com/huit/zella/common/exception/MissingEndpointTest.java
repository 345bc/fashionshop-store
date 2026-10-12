package com.huit.zella.common.exception;

import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.mock.web.MockServletContext;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.support.AnnotationConfigWebApplicationContext;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class MissingEndpointTest {
    @Configuration
    @EnableWebMvc
    static class Config implements WebMvcConfigurer {
        @Bean GlobalExceptionHandler errors() { return new GlobalExceptionHandler(); }
        @Override public void addResourceHandlers(ResourceHandlerRegistry registry) {
            registry.addResourceHandler("/**").addResourceLocations("classpath:/static/");
        }
    }

    @Test void disabledSimulationEndpointReturns404InsteadOf500() throws Exception {
        try (var context = new AnnotationConfigWebApplicationContext()) {
            context.setServletContext(new MockServletContext());
            context.register(Config.class);
            context.refresh();
            var mvc = MockMvcBuilders.webAppContextSetup(context).build();
            mvc.perform(get("/api/v1/order-test/enabled"))
                    .andExpect(status().isNotFound())
                    .andExpect(jsonPath("code").value("ENDPOINT_NOT_FOUND"))
                    .andExpect(jsonPath("path").value("/api/v1/order-test/enabled"));
        }
    }
}
