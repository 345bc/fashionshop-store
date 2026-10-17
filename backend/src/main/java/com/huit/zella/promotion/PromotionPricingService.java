package com.huit.zella.promotion;

import com.huit.zella.product.Product;
import java.math.*;
import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor
public class PromotionPricingService {
    private final PromotionRepository repository;
    private final Clock orderClock;

    public record Offer(Long promotionId, BigDecimal percent) {
        public BigDecimal price(BigDecimal original) {
            BigDecimal discounted = original.subtract(original.multiply(percent).divide(new BigDecimal("100"),0,RoundingMode.DOWN));
            if (original.compareTo(new BigDecimal("1000")) < 0) return discounted;
            return discounted.divide(new BigDecimal("1000"), 0, RoundingMode.HALF_UP)
                .multiply(new BigDecimal("1000")).min(original);
        }
    }
    @Transactional(readOnly=true)
    public Map<Long,Offer> offers(Collection<Product> products) {
        Instant now=orderClock.instant();
        var campaigns=repository.effective(now);
        Map<Long,Offer> result=new HashMap<>();
        for(var product:products) {
            if(product.isActive() && product.getCategory()!=null && Boolean.TRUE.equals(product.getCategory().getIsActive())
                    && product.getCreatedAt()!=null && product.getCreatedAt().isAfter(now.minus(7,ChronoUnit.DAYS)) && !product.getCreatedAt().isAfter(now))
                result.put(product.getId(), new Offer(null,new BigDecimal("5")));
        }
        for(var campaign:campaigns) {
            if(!"SELECTED".equals(campaign.getTargetMode())) continue;
            Set<Long> selected=new HashSet<>();
            campaign.getProducts().forEach(p->selected.add(p.getId()));
            for(var product:products) {
                boolean matches=selected.contains(product.getId());
                if(!matches || !product.isActive() || !Boolean.TRUE.equals(product.getCategory().getIsActive())) continue;
                Offer old=result.get(product.getId());
                if(old==null || campaign.getDiscountPercent().compareTo(old.percent())>0)
                    result.put(product.getId(),new Offer(campaign.getId(),campaign.getDiscountPercent()));
            }
        }
        return result;
    }
    public BigDecimal price(Product product,BigDecimal original,Map<Long,Offer> offers) {
        Offer offer=offers.get(product.getId());
        return offer==null?original:offer.price(original);
    }
}
