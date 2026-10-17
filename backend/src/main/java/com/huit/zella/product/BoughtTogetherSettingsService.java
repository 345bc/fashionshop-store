package com.huit.zella.product;

import com.huit.zella.common.exception.BusinessException;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;

@Service @RequiredArgsConstructor
public class BoughtTogetherSettingsService {
    private final JdbcTemplate jdbc;

    public record Settings(
        @Min(1) @Max(365) int windowDays,
        @NotNull @DecimalMin("0.000001") @DecimalMax("1") @Digits(integer=1, fraction=6) BigDecimal minSupport,
        @NotNull @DecimalMin("0") @DecimalMax("1") @Digits(integer=1, fraction=6) BigDecimal minConfidence,
        @NotNull @DecimalMin("0") @DecimalMax("100") @Digits(integer=3, fraction=4) BigDecimal minLift,
        @Min(1) @Max(24) int maxRecommendations,
        @NotNull Boolean enabled
    ) {}

    @Transactional(readOnly=true)
    public Settings get() {
        var rows=jdbc.query("select window_days,min_support,min_confidence,min_lift,max_recommendations,enabled from bought_together_settings where id=1",
            (rs,row)->new Settings(rs.getInt(1),rs.getBigDecimal(2),rs.getBigDecimal(3),rs.getBigDecimal(4),rs.getInt(5),rs.getBoolean(6)));
        if(rows.isEmpty()) throw missing();
        return rows.getFirst();
    }

    @Transactional
    public Settings save(Settings settings) {
        // Legacy min_cooccurrence is retained in V49's schema, but is no longer read or used.
        int updated=jdbc.update("update bought_together_settings set window_days=?,min_support=?,min_confidence=?,min_lift=?,max_recommendations=?,enabled=? where id=1",
            settings.windowDays(),settings.minSupport(),settings.minConfidence(),settings.minLift(),settings.maxRecommendations(),settings.enabled());
        if(updated!=1) throw missing();
        return settings;
    }

    private BusinessException missing() {
        return new BusinessException(HttpStatus.NOT_FOUND,"BOUGHT_TOGETHER_SETTINGS_NOT_FOUND","Chưa có cấu hình gợi ý mua kèm. Kiểm tra migration V49.");
    }
}
