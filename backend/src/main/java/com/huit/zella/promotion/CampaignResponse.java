package com.huit.zella.promotion;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
public record CampaignResponse(Long id,String kind,String name,String description,
    Instant startsAt,Instant endsAt,boolean enabled,String status,
    String code,String discountType,BigDecimal discountValue,BigDecimal minOrderAmount,
    BigDecimal maxDiscountAmount,Integer usageLimit,Integer usedCount,
    BigDecimal discountPercent,String targetMode,List<ProductOption> products,List<Usage> usages,
    boolean redeemable,Integer pointsRequired,String imageUrl,boolean isDisplay) {
    public record ProductOption(Long id,String name,Long categoryId,String categoryName) {
        public ProductOption(Long id,String name) { this(id,name,null,null); }
    }
    public record Usage(String orderCode,String buyer,BigDecimal discountAmount,Instant usedAt,String paymentStatus,String discountType,Integer pointsRequired) {}
}
