package com.huit.zella.voucher;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.Order;
import com.huit.zella.order.CheckoutPricingService;
import com.huit.zella.order.CheckoutPriceResponse;
import java.math.*;
import java.time.*;
import java.util.Locale;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor
public class VoucherService {
    private final VoucherRepository vouchers;
    private final Clock orderClock;
    private final CheckoutPricingService pricing;
    public void prepare(Order order,Long userId,String shippingMethod) { pricing.prepare(order,userId,shippingMethod); }
    public CheckoutPriceResponse snapshot(Order order) { return pricing.snapshot(order); }
    @Transactional
    public void apply(Order order,Long userId,String code) {
        apply(order,userId,code,true);
    }
    @Transactional
    public CheckoutPriceResponse quote(java.util.List<com.huit.zella.cart.CartItemRequest> items, Long userId, String code,
            com.huit.zella.cart.CartService cart) {
        return quote(items,userId,code,"STANDARD",cart);
    }
    @Transactional
    public CheckoutPriceResponse quote(java.util.List<com.huit.zella.cart.CartItemRequest> items, Long userId, String code,
            String shippingMethod,com.huit.zella.cart.CartService cart) {
        var result=cart.quote(items);
        if(result.items().isEmpty() || result.items().stream().anyMatch(item -> !item.purchasable())) throw error("Giỏ hàng có sản phẩm không thể đặt");
        Order order=new Order(); order.setSubtotal(result.subtotal()); order.setTotalAmount(result.subtotal());
        prepare(order,userId,shippingMethod);
        apply(order,userId,code,false);
        return snapshot(order);
    }
    private void apply(Order order,Long userId,String code,boolean reserve) {
        if(code==null || code.isBlank()) return;
        Voucher voucher=vouchers.lockCode(code.trim().toUpperCase(Locale.ROOT)).orElseThrow(()->error("Không tìm thấy voucher"));
        LocalDateTime now=LocalDateTime.now(orderClock);
        if(voucher.isRedeemable() || !voucher.isActive() || voucher.getStartDate().isAfter(now) || !voucher.getEndDate().isAfter(now)
                || (voucher.getOwner()!=null && (userId==null || !voucher.getOwner().getUser().getId().equals(userId)))
                || (voucher.getUsageLimit()!=null && voucher.getUsedCount()>=voucher.getUsageLimit())
                || order.getSubtotal().compareTo(voucher.getMinOrderAmount())<0) throw error("Voucher không khả dụng hoặc đơn chưa đủ điều kiện");
        BigDecimal couponBase=order.getSubtotal().subtract(order.getMembershipDiscountAmount());
        BigDecimal discount=switch(voucher.getDiscountType()) {
            case "FIXED" -> voucher.getDiscountValue();
            case "PERCENT" -> couponBase.multiply(voucher.getDiscountValue()).divide(new BigDecimal("100"),0,RoundingMode.DOWN)
                    .min(voucher.getDiscountAmount().signum()>0?voucher.getDiscountAmount():couponBase);
            case "GIFT" -> BigDecimal.ZERO;
            default -> throw error("Loại voucher chưa được hỗ trợ");
        };
        discount=discount.max(BigDecimal.ZERO).min(couponBase).add(order.getMembershipDiscountAmount());
        order.setDiscountAmount(discount); order.setTotalAmount(order.getSubtotal().add(order.getShippingFee()).subtract(discount));
        if(order.getTotalAmount().signum()<=0) throw error("Đơn online phải có số tiền thanh toán lớn hơn 0");
        if("GIFT".equals(voucher.getDiscountType())) {
            String note="[Gói quà và thiệp] "+(order.getNote()==null?"":order.getNote());
            if(note.length()>500) throw error("Ghi chú quá dài để thêm yêu cầu gói quà");
            order.setNote(note);
        }
        order.setVoucher(voucher);
        if(reserve) voucher.setUsedCount(Math.addExact(voucher.getUsedCount()==null?0:voucher.getUsedCount(),1));
    }
    @Transactional
    public void release(Order order) {
        if(order.getVoucher()==null || "PAID".equals(order.getPaymentStatus())) return;
        Voucher voucher=vouchers.lock(order.getVoucher().getId()).orElseThrow();
        voucher.setUsedCount(Math.max(0,voucher.getUsedCount()-1));
        order.setVoucher(null);
    }
    private BusinessException error(String message) { return new BusinessException(HttpStatus.CONFLICT,"INVALID_VOUCHER",message); }
}
