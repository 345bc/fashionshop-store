package com.huit.zella.product;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;

@Service @RequiredArgsConstructor
public class FeaturedProductService {
    private final FeaturedProductStore store;
    private final ProductService products;
    private final Clock orderClock;
    private final FeaturedProductSettingsService settings;
    private Snapshot cached;
    public record Score(Long productId,long transactions,long netQuantity,double support,double adjustedRating,double score) {}
    private record Snapshot(Instant from,Instant to,FeaturedProductStore.Data data,List<Score> scores,int days,int purchaseWeight,int reviewWeight) {}
    public record Item(ProductCardResponse product,long transactions,long netQuantity,double support,double adjustedRating,double score) {}
    public record Result(Instant windowFrom,Instant windowTo,Instant computedAt,long totalTransactions,double baselineRating,List<Item> products,String title,String description,boolean isDisplay) {}

    static List<Score> rank(FeaturedProductStore.Data data) {
        return rank(data,60,40);
    }
    static List<Score> rank(FeaturedProductStore.Data data,int purchaseWeight,int reviewWeight) {
        if(data.totalTransactions()<=0) return List.of();
        long max=data.products().stream().mapToLong(FeaturedProductStore.Observation::transactions).max().orElse(0);
        if(max<=0) return List.of();
        return data.products().stream().filter(p->p.transactions()>0).map(p->{
            double support=(double)p.transactions()/data.totalTransactions();
            double adjusted=(p.reviewCount()*p.rating()+10*data.baselineRating())/(p.reviewCount()+10.0);
            double score=(purchaseWeight/100.0)*((double)p.transactions()/max)+(reviewWeight/100.0)*(adjusted/5);
            return new Score(p.productId(),p.transactions(),p.netQuantity(),support,adjusted,score);
        }).sorted(Comparator.comparingDouble(Score::score).reversed()
                .thenComparing(Comparator.comparingLong(Score::netQuantity).reversed()).thenComparing(Score::productId)).toList();
    }
    private synchronized Snapshot snapshot(FeaturedProductSettingsService.Settings config) {
        Instant now=orderClock.instant();
        if(cached==null || now.isBefore(cached.to()) || !now.isBefore(cached.to().plusSeconds(900)) || cached.days()!=config.windowDays() || cached.purchaseWeight()!=config.purchaseWeight() || cached.reviewWeight()!=config.reviewWeight()) {
            Instant from=now.minus(Duration.ofDays(config.windowDays()));
            var data=store.load(from,now);
            cached=new Snapshot(from,now,data,rank(data,config.purchaseWeight(),config.reviewWeight()),config.windowDays(),config.purchaseWeight(),config.reviewWeight());
        }
        return cached;
    }
    @Transactional(readOnly=true)
    public Result get(int size) {
        var config=settings.get();
        if(!config.isDisplay()) {
            var now=orderClock.instant();
            return new Result(now.minus(Duration.ofDays(config.windowDays())),now,now,0,3,List.of(),config.title(),config.description(),false);
        }
        var snapshot=snapshot(config);
        var ids=snapshot.scores().stream().map(Score::productId).toList();
        var cards=products.featuredCards(ids);
        Map<Long,ProductCardResponse> byId=new HashMap<>();cards.forEach(c->byId.put(c.id(),c));
        var items=snapshot.scores().stream().filter(s->byId.containsKey(s.productId())).limit(Math.clamp(size,1,24))
                .map(s->new Item(byId.get(s.productId()),s.transactions(),s.netQuantity(),s.support(),s.adjustedRating(),s.score())).toList();
        return new Result(snapshot.from(),snapshot.to(),snapshot.to(),snapshot.data().totalTransactions(),snapshot.data().baselineRating(),items,config.title(),config.description(),true);
    }
}
