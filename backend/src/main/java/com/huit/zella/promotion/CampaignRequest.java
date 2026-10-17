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
    Boolean redeemable,Integer pointsRequired,
    @Size(max=500) @Pattern(regexp="https?://[^\\s]+") String imageUrl, Boolean isDisplay) {
    public CampaignRequest(String name,String description,Instant startsAt,Instant endsAt,boolean enabled,
        String code,String discountType,BigDecimal discountValue,BigDecimal minOrderAmount,
        BigDecimal maxDiscountAmount,Integer usageLimit,BigDecimal discountPercent,String targetMode,
        List<Long> productIds,Boolean redeemable,Integer pointsRequired) {
        this(name,description,startsAt,endsAt,enabled,code,discountType,discountValue,minOrderAmount,
            maxDiscountAmount,usageLimit,discountPercent,targetMode,productIds,redeemable,pointsRequired,null,null);
    }
    public CampaignRequest {
        redeemable = Boolean.TRUE.equals(redeemable);
    }
}
