package com.huit.zella.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.awt.*;
import java.net.URI;

/** Opens Swagger UI only when a local developer explicitly enables it. */
@Component
class SwaggerUiLauncher {

    private static final Logger log = LoggerFactory.getLogger(SwaggerUiLauncher.class);

    private final boolean autoOpen;
    private final int serverPort;

    SwaggerUiLauncher(
            @Value("${app.swagger.auto-open:false}") boolean autoOpen,
            @Value("${server.port:8080}") int serverPort) {
        this.autoOpen = autoOpen;
        this.serverPort = serverPort;
    }

    @EventListener(ApplicationReadyEvent.class)
    void openSwaggerUi() {
        if (!autoOpen) {
            return;
        }

        String swaggerUrl = "http://localhost:" + serverPort + "/swagger-ui.html";
        if (!Desktop.isDesktopSupported()) {
            log.info("Swagger UI is available at {}", swaggerUrl);
            return;
        }

        try {
            Desktop.getDesktop().browse(URI.create(swaggerUrl));
        } catch (Exception exception) {
            log.warn("Could not open Swagger UI automatically. Open {} manually.", swaggerUrl);
        }
    }
}
