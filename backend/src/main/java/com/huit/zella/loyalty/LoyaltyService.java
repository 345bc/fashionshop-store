package com.huit.zella.loyalty;

import com.huit.zella.customer.*;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.Order;
import com.huit.zella.orderreturn.ReturnRepository;
import com.huit.zella.voucher.*;
import java.math.*;
import java.time.*;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor
public class LoyaltyService {
    private final CustomerRepository customers;
    private final RewardTransactionRepository transactions;
    private final VoucherRepository vouchers;
    private final ReturnRepository returns;
    private final Clock orderClock;
    public record Offer(Long id,String name,String code,int points,String type,BigDecimal value,BigDecimal cap,BigDecimal minimum,LocalDateTime expiresAt,boolean used) {}
    public record Summary(int balance,int adjustmentPoints,String tier,BigDecimal spending,List<Offer> rewards,com.huit.zella.common.api.PageResponse<Offer> vouchers) {}
    public record Entry(Long id,int points,int balanceAfter,String description,LocalDateTime createdAt) {}

    @Transactional(readOnly=true)
    public Summary summary(Long userId) {
        var customer=customers.findByUserId(userId).orElseThrow(()->error("CUSTOMER_NOT_FOUND","Không tìm thấy hồ sơ khách hàng"));
        return new Summary(customer.getRewardPoints(),customer.getRewardPointAdjustment(),customer.getMembershipTier(),customer.getTotalSpending(),
                vouchers.rewards(now()).stream().map(this::offer).toList(),com.huit.zella.common.api.PageResponse.from(wallet(userId,PageRequest.of(0,10,Sort.by(Sort.Direction.DESC,"id")))));
    }
    @Transactional(readOnly=true)
    public Page<Offer> wallet(Long userId,Pageable pageable) {
        return vouchers.findByOwnerUserId(userId,pageable).map(this::offer);
    }
    @Transactional(readOnly=true)
    public Page<Entry> history(Long userId,LocalDate from,LocalDate to,Pageable pageable) {
        LocalDate today=orderClock.instant().atZone(ZoneId.of("Asia/Ho_Chi_Minh")).toLocalDate();
        if(to==null) to=today;
        if(from==null) from=to.minusMonths(1);
        if(from.isAfter(to)) throw error("INVALID_DATE_RANGE","Ngày bắt đầu phải trước ngày kết thúc");
        LocalDateTime start=from.atStartOfDay(ZoneId.of("Asia/Ho_Chi_Minh")).withZoneSameInstant(ZoneOffset.UTC).toLocalDateTime();
        LocalDateTime end=to.plusDays(1).atStartOfDay(ZoneId.of("Asia/Ho_Chi_Minh")).withZoneSameInstant(ZoneOffset.UTC).toLocalDateTime();
        return transactions.history(userId,start,end,pageable).map(item->new Entry(item.getId(),item.getPoints(),item.getBalanceAfter(),item.getDescription(),item.getCreatedAt()));
    }
    @Transactional
    public Offer redeem(Long userId,Long rewardId,String key) {
        Customer customer=customers.lockByUserId(userId).orElseThrow();
        var previous=vouchers.findByRedemptionKey(key);
        if(previous.isPresent()) {
            if(!previous.get().getOwner().getId().equals(customer.getId())) throw error("INVALID_REDEMPTION","Yêu cầu đổi ưu đãi không hợp lệ");
            if(previous.get().getSourceRewardId()!=null && !previous.get().getSourceRewardId().equals(rewardId)) throw error("INVALID_REDEMPTION","Mã yêu cầu đã được dùng cho ưu đãi khác");
            return offer(previous.get());
        }
        Voucher template=vouchers.lock(rewardId).orElseThrow(()->error("REWARD_NOT_FOUND","Không tìm thấy ưu đãi"));
        if(!template.isRedeemable() || template.getOwner()!=null || !valid(template) || (template.getUsageLimit()!=null && template.getUsedCount()>=template.getUsageLimit()) || template.getPointsRequired()==null || template.getPointsRequired()<=0) throw error("REWARD_UNAVAILABLE","Ưu đãi đã ngừng đổi");
        if(customer.getRewardPoints()<template.getPointsRequired()) throw error("INSUFFICIENT_POINTS","Bạn chưa đủ điểm để đổi ưu đãi");
        var voucher=new Voucher(); voucher.setCode("ZEL-"+UUID.randomUUID().toString().replace("-","").toUpperCase(Locale.ROOT));
        voucher.setSourceRewardId(template.getId());voucher.setName(template.getName());voucher.setDescription(template.getDescription()); voucher.setDiscountType(template.getDiscountType()); voucher.setDiscountValue(template.getDiscountValue());
        voucher.setDiscountAmount(template.getDiscountAmount()); voucher.setMinOrderAmount(template.getMinOrderAmount()); voucher.setUsageLimit(1);
        voucher.setOwner(customer); voucher.setRedemptionKey(key); voucher.setCreatedAt(now()); voucher.setStartDate(now());
        voucher.setEndDate(now().plusDays(30)); voucher.setPointsRequired(template.getPointsRequired());
        template.setUsedCount(Math.addExact(template.getUsedCount(),1));
        vouchers.saveAndFlush(voucher);
        record(customer,-template.getPointsRequired(),"Đổi "+template.getDescription(),"REDEEM-"+key);
        return offer(voucher);
    }
    @Transactional
    public void earned(Order order) {
        if(order.getCustomer()==null) return;
        if(order.getStatus()!=com.huit.zella.order.OrderStatus.DELIVERED || !"PAID".equals(order.getPaymentStatus())) throw error("ORDER_NOT_DELIVERED","Chỉ tích điểm khi đơn đã thanh toán và giao thành công");
        Customer customer=customers.lockByUserId(order.getCustomer().getId()).orElseThrow();
        String key="ORDER-EARN-"+order.getId();
        if(transactions.existsByReferenceKey(key)) return;
        int points=points(order.getOriginalSubtotal()); order.setPointsEarned(points);
        customer.setTotalSpending(customer.getTotalSpending().add(order.getSubtotal().subtract(order.getDiscountAmount())));
        evaluateTier(customer);
        record(customer,points,"Đơn "+order.getCode()+" giao thành công",key);
    }
    @Transactional
    public void reverse(Order order,Long returnId,BigDecimal refundedMerchandise) {
        if(order.getCustomer()==null || !transactions.existsByReferenceKey("ORDER-EARN-"+order.getId())) return;
        Customer customer=customers.lockByUserId(order.getCustomer().getId()).orElseThrow();
        String key="ORDER-RETURN-"+returnId;
        if(transactions.existsByReferenceKey(key)) return;
        BigDecimal remaining=order.getOriginalSubtotal().subtract(returns.receivedOriginalValue(order.getId())).max(BigDecimal.ZERO);
        int target=points(remaining), before=order.getPointsEarned();
        int delta=target-before;
        order.setPointsEarned(target);
        customer.setTotalSpending(customer.getTotalSpending().subtract(refundedMerchandise).max(BigDecimal.ZERO));
        evaluateTier(customer);
        record(customer,delta,"Điều chỉnh điểm hàng trả của "+order.getCode(),key);
    }
    private void evaluateTier(Customer customer) {
        BigDecimal total = customer.getTotalSpending();
        String newTier = "STANDARD";
        if (total.compareTo(new BigDecimal("20000000")) >= 0) {
            newTier = "PLATINUM";
        } else if (total.compareTo(new BigDecimal("10000000")) >= 0) {
            newTier = "GOLD";
        } else if (total.compareTo(new BigDecimal("5000000")) >= 0) {
            newTier = "SILVER";
        }
        if (!newTier.equals(customer.getMembershipTier())) {
            customer.setMembershipTier(newTier);
            customer.setTierUpgradedAt(orderClock.instant());
        }
    }
    public static int points(BigDecimal subtotal) { return subtotal.divide(new BigDecimal("10000"),0,RoundingMode.DOWN).intValueExact(); }
    private void record(Customer customer,int delta,String description,String key) {
        if(delta>=0) {
            int offset=Math.min(delta,customer.getRewardPointAdjustment());
            customer.setRewardPointAdjustment(customer.getRewardPointAdjustment()-offset);
            customer.setRewardPoints(Math.addExact(customer.getRewardPoints(),delta-offset));
            if(offset>0) description+=" · Điều chỉnh "+offset+" điểm từ hàng trả";
        } else {
            int revoked=Math.negateExact(delta);
            int deducted=Math.min(customer.getRewardPoints(),revoked);
            customer.setRewardPoints(customer.getRewardPoints()-deducted);
            customer.setRewardPointAdjustment(Math.addExact(customer.getRewardPointAdjustment(),revoked-deducted));
        }
        var entry=new RewardTransaction(); entry.setCustomer(customer); entry.setPoints(delta); entry.setBalanceAfter(customer.getRewardPoints());
        entry.setDescription(description); entry.setReferenceKey(key); entry.setCreatedAt(now()); transactions.save(entry);
    }
    private boolean valid(Voucher voucher) { return voucher.isActive() && !voucher.getStartDate().isAfter(now()) && voucher.getEndDate().isAfter(now()); }
    private Offer offer(Voucher v) { return new Offer(v.getId(),v.getName()==null?v.getDescription():v.getName(),v.getCode(),v.getPointsRequired()==null?0:v.getPointsRequired(),v.getDiscountType(),v.getDiscountValue(),v.getDiscountAmount(),v.getMinOrderAmount(),v.getEndDate(),v.getUsageLimit()!=null && v.getUsedCount()>=v.getUsageLimit()); }
    private LocalDateTime now() { return LocalDateTime.now(orderClock); }
    private BusinessException error(String code,String message) { return new BusinessException(HttpStatus.CONFLICT,code,message); }
}
