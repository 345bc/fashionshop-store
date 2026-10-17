package com.huit.zella.config;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.config.ConfigDataEnvironmentPostProcessor;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.StandardEnvironment;
import java.util.Map;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class SecurityProfileGroupTest {
    @Test void localAndProductProfilesActivateJwtSecurity() {
        for (String profile : List.of("local", "product")) {
            var environment = new StandardEnvironment();
            environment.getPropertySources().addFirst(new MapPropertySource("test", Map.of(
                    "spring.profiles.active", profile,
                    "spring.config.location", "classpath:/application.yml")));
            ConfigDataEnvironmentPostProcessor.applyTo(environment);
            assertTrue(List.of(environment.getActiveProfiles()).contains("jwt-auth"), profile + " must activate JWT security");
        }
    }
}
