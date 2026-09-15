package com.huit.zella.core;

import com.huit.zella.common.api.ApiResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.huit.zella.common.api.ApiResponse;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class HealthController {
    private final JdbcTemplate jdbcTemplate;
    private final String projectName;
    private final String version;

    public HealthController(
            JdbcTemplate jdbcTemplate,
            @Value("${app.project.name}") String projectName,
            @Value("${app.project.version}") String version
    ) {
        this.jdbcTemplate = jdbcTemplate;
        this.projectName = projectName;
        this.version = version;
    }

    @GetMapping("/health")
    ApiResponse<Map<String, Object>> health() {
        Integer database = jdbcTemplate.queryForObject("SELECT 1", Integer.class);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("status", "UP");
        data.put("database", database != null && database == 1 ? "UP" : "DOWN");
        data.put("time", Instant.now());
        return ApiResponse.success(data);
    }

    @GetMapping("/project-info")
    ApiResponse<Map<String, Object>> projectInfo() {
        return ApiResponse.success(Map.of(
                "name", projectName,
                "version", version
        ));
    }
}
