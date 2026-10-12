package com.huit.zella.promotion;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
public record CampaignRequest(
    @NotBlank @Size(max=200) String name,
    @Size(max=500) String description,
    @NotNull Instant startsAt,@NotNull Instant endsAt,boolean enabled,
    String code,String discountType,BigDecimal discountValue,BigDecimal minOrderAmount,
    BigDecimal maxDiscountAmount,Integer usageLimit,
    BigDecimal discountPercent,String targetMode,List<Long> productIds,
    boolean redeemable,Integer pointsRequired) {}
