package com.huit.zella.product;

import com.huit.zella.common.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.*;
import java.time.*;
import java.util.*;

@Service @RequiredArgsConstructor
public class BoughtTogetherService {
    private final BoughtTogetherStore store;
    private final ProductService products;
    private final Clock orderClock;
    private final BoughtTogetherSettingsService settings;
    private Snapshot cached;
    private RuleSnapshot cachedRules;
    private record Snapshot(Instant computedAt,FpGrowth.Model model,int windowDays,BigDecimal minSupport) {}
    private record RuleSnapshot(Snapshot snapshot,BigDecimal minConfidence,List<FpGrowth.Rule> rules) {}
    private record Score(long id,FpGrowth.Rule rule) {}
    public record Item(ProductCardResponse product,int transactions,double support,double confidence,double lift,
                       List<Long> antecedent,List<Long> consequent) {}
    public record Result(Instant computedAt,int totalTransactions,List<Item> products) {}
    public record Status(Instant computedAt,Instant windowFrom,Instant windowTo,int totalTransactions,
                         int totalProducts,int frequentItemsets,int maximumItemsetSize,int totalRules,
                         int minimumCount,BoughtTogetherSettingsService.Settings settings) {}
    public record Preview(String code,String message,int sourceTransactions,int frequentItemsets,int qualifyingRules,Result result,
                          List<Long> contextProductIds,Map<Long,String> productNames) {}
    public record FrequentItemset(List<Long> items,int count,double support) {}
    public record MiningPage<T>(List<T> content,int page,int size,int totalElements,int totalPages) {}

    private synchronized Snapshot snapshot(BoughtTogetherSettingsService.Settings config,boolean force) {
        Instant now=orderClock.instant();
        if(force || cached==null || now.isBefore(cached.computedAt()) || !now.isBefore(cached.computedAt().plusSeconds(900))
            || cached.windowDays()!=config.windowDays() || cached.minSupport().compareTo(config.minSupport())!=0) {
            var baskets=store.load(now.minus(Duration.ofDays(config.windowDays())),now);
            cached=new Snapshot(now,FpGrowth.mine(baskets,Math.max(1,minimumCount(baskets.size(),config))),config.windowDays(),config.minSupport());
        }
        return cached;
    }

    private synchronized List<FpGrowth.Rule> rules(Snapshot snapshot,BoughtTogetherSettingsService.Settings config) {
        if(cachedRules==null || cachedRules.snapshot()!=snapshot || cachedRules.minConfidence().compareTo(config.minConfidence())!=0)
            cachedRules=new RuleSnapshot(snapshot,config.minConfidence(),FpGrowth.rules(snapshot.model(),config.minConfidence().doubleValue()));
        return cachedRules.rules();
    }

    private int minimumCount(int transactions,BoughtTogetherSettingsService.Settings config) {
        return config.minSupport().multiply(BigDecimal.valueOf(transactions)).setScale(0,RoundingMode.CEILING).intValueExact();
    }

    private Set<Long> context(Collection<Long> ids) {
        if(ids==null || ids.isEmpty() || ids.size()>50 || ids.stream().anyMatch(id->id==null || id<=0))
            throw new BusinessException(HttpStatus.BAD_REQUEST,"INVALID_RECOMMENDATION_CONTEXT","Chọn từ 1 đến 50 mã sản phẩm hợp lệ.");
        return new TreeSet<>(ids);
    }

    private List<FpGrowth.Rule> matchingRules(Snapshot snapshot,Set<Long> context,BoughtTogetherSettingsService.Settings config) {
        return rules(snapshot,config).stream().filter(r->context.containsAll(r.antecedent()))
            .filter(r->r.consequent().stream().anyMatch(id->!context.contains(id)))
            .filter(r->r.lift()>config.minLift().doubleValue()).toList();
    }

    private Result result(Snapshot snapshot,List<FpGrowth.Rule> rules,Set<Long> context,int size) {
        Map<Long,Score> scores=new LinkedHashMap<>();
        // Rules are ranked; use the best matching rule per missing product.
        for(var rule:rules) for(Long id:rule.consequent()) if(!context.contains(id)) scores.putIfAbsent(id,new Score(id,rule));
        if(scores.isEmpty()) return new Result(snapshot.computedAt(),snapshot.model().transactions(),List.of());
        Map<Long,ProductCardResponse> cards=new HashMap<>();
        products.featuredCards(new ArrayList<>(scores.keySet())).forEach(c->cards.put(c.id(),c));
        return new Result(snapshot.computedAt(),snapshot.model().transactions(),scores.values().stream().filter(s->cards.containsKey(s.id()))
            .limit(Math.clamp(size,1,24)).map(s->{
                var r=s.rule();
                return new Item(cards.get(s.id()),r.count(),r.support(),r.confidence(),r.lift(),r.antecedent(),r.consequent());
            }).toList());
    }

    @Transactional(readOnly=true)
    public Result get(long productId,int size) { return get(List.of(productId),size); }

    @Transactional(readOnly=true)
    public Result get(Collection<Long> productIds,int size) {
        var context=context(productIds);
        var config=settings.get();
        if(!config.enabled()) return new Result(orderClock.instant(),0,List.of());
        var snapshot=snapshot(config,false);
        return result(snapshot,matchingRules(snapshot,context,config),context,Math.min(size,config.maxRecommendations()));
    }

    @Transactional(readOnly=true)
    public Status status(boolean rebuild) {
        var config=settings.get();
        var snapshot=snapshot(config,rebuild);
        var model=snapshot.model();
        return new Status(snapshot.computedAt(),snapshot.computedAt().minus(Duration.ofDays(config.windowDays())),snapshot.computedAt(),
            model.transactions(),model.counts().size(),model.itemsets().size(),model.itemsets().stream().mapToInt(s->s.items().size()).max().orElse(0),
            rules(snapshot,config).size(),minimumCount(model.transactions(),config),config);
    }

    @Transactional(readOnly=true)
    public MiningPage<FrequentItemset> itemsets(int page,int size,int level) {
        if(level<0) throw new BusinessException(HttpStatus.BAD_REQUEST,"INVALID_LEVEL","Cấp tập phổ biến phải từ 0 trở lên; 0 là tất cả.");
        var config=settings.get();
        var model=snapshot(config,false).model();
        var items=model.itemsets().stream().filter(s->level==0 || s.items().size()==level)
            .map(s->new FrequentItemset(s.items(),s.count(),(double)s.count()/model.transactions())).toList();
        return page(items,page,size);
    }

    @Transactional(readOnly=true)
    public MiningPage<FpGrowth.Rule> associationRules(int page,int size) {
        var config=settings.get();
        // Mining results use only minsup and minconf; lift is a recommendation filter.
        return page(rules(snapshot(config,false),config),page,size);
    }

    private <T> MiningPage<T> page(List<T> values,int page,int size) {
        int safePage=Math.max(0,page),safeSize=Math.clamp(size,1,100);
        int start=(int)Math.min((long)safePage*safeSize,values.size());
        return new MiningPage<>(values.subList(start,Math.min(start+safeSize,values.size())),safePage,safeSize,values.size(),
            (int)Math.ceil((double)values.size()/safeSize));
    }

    @Transactional(readOnly=true)
    public Preview preview(long productId) { return preview(List.of(productId)); }

    @Transactional(readOnly=true)
    public Preview preview(Collection<Long> productIds) {
        var context=context(productIds);
        var config=settings.get();
        var snapshot=snapshot(config,false);
        var model=snapshot.model();
        int source=context.size()==1?model.counts().getOrDefault(context.iterator().next(),0):
            model.itemsets().stream().filter(s->s.items().equals(new ArrayList<>(context))).mapToInt(FpGrowth.Itemset::count).findFirst().orElse(0);
        int itemsets=(int)model.itemsets().stream().filter(s->s.items().size()>1 && s.items().containsAll(context)).count();
        var matched=matchingRules(snapshot,context,config);
        var result=result(snapshot,matched,context,config.maxRecommendations());
        String code,message;
        if(!config.enabled()) { code="DISABLED"; message="Đang tắt hiển thị. Danh sách dưới đây chỉ là xem thử."; }
        else if(model.transactions()==0) { code="NO_TRANSACTIONS"; message="Chưa có đơn đã giao có lịch sử giao hàng trong khoảng thời gian xét."; }
        else if(context.size()==1 && source==0) { code="NO_PRODUCT_HISTORY"; message="Sản phẩm chưa có trong đơn hợp lệ hoặc đã được trả hết."; }
        else if(matched.isEmpty() && itemsets==0) { code="BELOW_SUPPORT"; message="Không có tập mua chung phù hợp đạt minsup."; }
        else if(matched.isEmpty()) { code="BELOW_RULE_THRESHOLDS"; message="Có tập phổ biến nhưng luật chưa đạt minconf hoặc bộ lọc lift của gợi ý."; }
        else if(result.products().isEmpty()) { code="NO_AVAILABLE_PRODUCTS"; message="Sản phẩm được gợi ý đang bị ẩn, danh mục bị ẩn hoặc hết tồn khả dụng."; }
        else { code="READY"; message="Đủ điều kiện hiển thị gợi ý theo các luật có vế trái nằm trong sản phẩm đang xét."; }
        Set<Long> ids=new TreeSet<>(context);
        result.products().forEach(item->{ ids.addAll(item.antecedent()); ids.addAll(item.consequent()); });
        return new Preview(code,message,source,itemsets,matched.size(),result,List.copyOf(context),store.productNames(ids));
    }
}
