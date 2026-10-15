package com.huit.zella.voucher;

import com.huit.zella.auth.User;
import com.huit.zella.customer.Customer;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.Order;
import java.math.BigDecimal;
import java.time.*;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class VoucherServiceTest {
    private final VoucherRepository repository=mock(VoucherRepository.class);
    private final Clock clock=Clock.fixed(Instant.parse("2026-10-10T00:00:00Z"),ZoneOffset.UTC);
    private final VoucherService service=new VoucherService(repository,clock,mock(com.huit.zella.order.CheckoutPricingService.class));
    private Order order;private Voucher voucher;
    @BeforeEach void setup() {
        order=new Order();order.setSubtotal(new BigDecimal("519000"));order.setShippingFee(new BigDecimal("30000"));
        voucher=new Voucher();voucher.setId(1L);voucher.setDiscountType("FIXED");voucher.setDiscountValue(new BigDecimal("50000"));
        voucher.setStartDate(LocalDateTime.now(clock).minusDays(1));voucher.setEndDate(LocalDateTime.now(clock).plusDays(1));voucher.setUsageLimit(1);
        when(repository.lockCode("CODE")).thenReturn(Optional.of(voucher));when(repository.lock(1L)).thenReturn(Optional.of(voucher));
    }
    @Test void usesServerSubtotalAndReleasesOnlyUnpaidReservation() {
        service.apply(order,1L," code ");assertEquals(new BigDecimal("499000"),order.getTotalAmount());assertEquals(1,voucher.getUsedCount());
        order.setPaymentStatus("PAID");service.release(order);assertEquals(1,voucher.getUsedCount());
        order.setPaymentStatus("PENDING");service.release(order);assertEquals(0,voucher.getUsedCount());assertNull(order.getVoucher());
        service.release(order);assertEquals(0,voucher.getUsedCount());
    }
    @Test void percentDiscountHonorsCapAndDoesNotReduceShipping() {
        voucher.setDiscountType("PERCENT");voucher.setDiscountValue(new BigDecimal("20"));voucher.setDiscountAmount(new BigDecimal("80000"));
        service.apply(order,1L,"CODE");assertEquals(new BigDecimal("80000"),order.getDiscountAmount());assertEquals(new BigDecimal("469000"),order.getTotalAmount());
    }
    @Test void couponAppliesAfterMembershipAndResponseSeparatesDiscounts() {
        order.setMembershipDiscountAmount(new BigDecimal("25950"));order.setMembershipDiscountPercent(new BigDecimal("5"));
        voucher.setDiscountType("PERCENT");voucher.setDiscountValue(new BigDecimal("10"));
        service.apply(order,1L,"CODE");
        assertEquals(0,new BigDecimal("75255").compareTo(order.getDiscountAmount()));
        assertEquals(0,new BigDecimal("473745").compareTo(order.getTotalAmount()));
    }
    @Test void cannotUseRewardTemplateAnotherOwnersOrAlreadyUsedVoucher() {
        voucher.setRedeemable(true);assertThrows(BusinessException.class,()->service.apply(order,1L,"CODE"));voucher.setRedeemable(false);
        Customer customer=new Customer();User user=new User();user.setId(2L);customer.setUser(user);voucher.setOwner(customer);
        assertThrows(BusinessException.class,()->service.apply(order,1L,"CODE"));assertThrows(BusinessException.class,()->service.apply(order,null,"CODE"));
        voucher.setOwner(null);voucher.setUsedCount(1);assertThrows(BusinessException.class,()->service.apply(order,1L,"CODE"));
    }
    @Test void expiredAndBelowMinimumAndZeroPayableOrdersAreRejected() {
        voucher.setEndDate(LocalDateTime.now(clock));assertThrows(BusinessException.class,()->service.apply(order,1L,"CODE"));
        voucher.setEndDate(LocalDateTime.now(clock).plusDays(1));voucher.setMinOrderAmount(new BigDecimal("600000"));assertThrows(BusinessException.class,()->service.apply(order,1L,"CODE"));
        voucher.setMinOrderAmount(BigDecimal.ZERO);voucher.setDiscountValue(new BigDecimal("999999"));order.setShippingFee(BigDecimal.ZERO);
        assertThrows(BusinessException.class,()->service.apply(order,1L,"CODE"));assertEquals(0,voucher.getUsedCount());
    }
}
