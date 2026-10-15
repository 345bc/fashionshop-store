package com.huit.zella.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    OpenAPI openApi(
            @Value("${app.project.name}") String projectName,
            @Value("${app.project.version}") String version
    ) {
        return new OpenAPI().info(new Info()
                .title(projectName + " API")
                .version(version)
                .description("REST API documentation generated from Spring controllers."));
    }
}
