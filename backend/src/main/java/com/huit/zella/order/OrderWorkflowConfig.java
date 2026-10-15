package com.huit.zella.order;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import java.time.Clock;

@Configuration
@EnableScheduling
public class OrderWorkflowConfig {
    @Bean
    public Clock orderClock() {
        return Clock.systemUTC();
    }
}

