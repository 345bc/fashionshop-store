package com.huit.zella.promotion;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.Comparator;
import java.util.List;
import com.huit.zella.product.ProductService;
import com.huit.zella.product.ProductCardResponse;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

@Service @RequiredArgsConstructor
public class NewProductSpotlightService {
    private final PromotionRepository promotions;
    private final Clock orderClock;
    private final ProductService products;
    private final AutomaticNewProductShowcaseService automatic;

    public record Spotlight(String campaignName, String title, String description,
                            String imageUrl, Instant startsAt, Instant endsAt, List<ProductCardResponse> products,
                            Long id, String targetMode) {}

    @Transactional(readOnly=true)
    public List<Spotlight> list() {
        Instant now=orderClock.instant();
        var page=PageRequest.of(0,12,Sort.by(Sort.Order.desc("createdAt"),Sort.Order.desc("id")));
        var result=new java.util.ArrayList<Spotlight>();
        var campaigns=promotions.effective(now).stream()
                .filter(c->"SELECTED".equals(c.getTargetMode()) && c.isDisplay() && c.isActive() && !c.getStartsAt().isAfter(now) && c.getEndsAt().isAfter(now)
                        && c.getImageUrl()!=null && !c.getImageUrl().isBlank())
                .sorted(Comparator.comparing(Promotion::getDiscountPercent).reversed().thenComparing(Promotion::getId))
                .toList();
        for(var c:campaigns) {
            List<ProductCardResponse> items;
            if("SELECTED".equals(c.getTargetMode())) {
                var ids=c.getProducts().stream().map(com.huit.zella.product.Product::getId).toList();
                if(ids.isEmpty()) continue;
                items=products.listSelectedCampaignProducts(ids,page).getContent();
            } else continue;
            if(items.isEmpty()) continue;
            result.add(new Spotlight(c.getName(),c.getName(),c.getDescription(),c.getImageUrl(),
                    c.getStartsAt(),c.getEndsAt(),items,c.getId(),c.getTargetMode()));
        }
        var newProducts=automatic.get();
        if(newProducts!=null) result.add(newProducts);
        return result;
    }

    @Transactional(readOnly=true)
    public Spotlight get() {
        return automatic.get();
    }
}
