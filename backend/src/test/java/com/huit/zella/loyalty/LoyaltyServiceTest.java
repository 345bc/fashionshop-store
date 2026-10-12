package com.huit.zella.loyalty;

import com.huit.zella.auth.User;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.customer.*;
import com.huit.zella.order.*;
import com.huit.zella.orderreturn.ReturnRepository;
import com.huit.zella.voucher.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class LoyaltyServiceTest {
    private final CustomerRepository customers=mock(CustomerRepository.class);
    private final RewardTransactionRepository ledger=mock(RewardTransactionRepository.class);
    private final VoucherRepository vouchers=mock(VoucherRepository.class);
    private final ReturnRepository returns=mock(ReturnRepository.class);
    private final Clock clock=Clock.fixed(Instant.parse("2026-10-10T00:00:00Z"),ZoneOffset.UTC);
    private final LoyaltyService service=new LoyaltyService(customers,ledger,vouchers,returns,clock);
    private Customer customer; private Order order; private Voucher reward;
    @BeforeEach void setup() {
        User user=new User();user.setId(7L);
        customer=new Customer();customer.setId(3L);customer.setUser(user);customer.setRewardPoints(1000);
        when(customers.lockByUserId(7L)).thenReturn(Optional.of(customer));
        order=new Order();order.setId(10L);order.setCode("ORD-TEST");order.setCustomer(user);order.setStatus(OrderStatus.DELIVERED);order.setPaymentStatus("PAID");
        order.setSubtotal(new BigDecimal("519999"));order.setDiscountAmount(new BigDecimal("50000"));
        reward=new Voucher();reward.setId(1L);reward.setDescription("Voucher 50K");reward.setRedeemable(true);reward.setPointsRequired(500);
        reward.setDiscountType("FIXED");reward.setDiscountValue(new BigDecimal("50000"));reward.setStartDate(LocalDateTime.now(clock).minusDays(1));reward.setEndDate(LocalDateTime.now(clock).plusDays(1));
        when(vouchers.lock(1L)).thenReturn(Optional.of(reward));
    }
    @Test void awardsWholePointsBeforeDiscountOnlyOnce() {
        service.earned(order);
        assertEquals(1051,customer.getRewardPoints());assertEquals(51,order.getPointsEarned());
        assertEquals(new BigDecimal("469999"),customer.getTotalSpending());
        when(ledger.existsByReferenceKey("ORDER-EARN-10")).thenReturn(true);
        service.earned(order);assertEquals(1051,customer.getRewardPoints());verify(ledger,times(1)).save(any());
    }
    @Test void cannotEarnBeforeDeliveryAndGuestsEarnNothing() {
        order.setStatus(OrderStatus.CONFIRMED);assertThrows(BusinessException.class,()->service.earned(order));
        order.setCustomer(null);service.earned(order);verifyNoInteractions(ledger);
    }
    @Test void returnKeepsBalanceAtZeroAndNextDeliverySettlesAdjustment() {
        customer.setRewardPoints(0);order.setPointsEarned(51);
        when(ledger.existsByReferenceKey("ORDER-EARN-10")).thenReturn(true);
        when(returns.receivedValue(10L)).thenReturn(new BigDecimal("110000"));
        service.reverse(order,2L,new BigDecimal("100000"));
        assertEquals(40,order.getPointsEarned());assertEquals(0,customer.getRewardPoints());assertEquals(11,customer.getRewardPointAdjustment());
        when(ledger.existsByReferenceKey("ORDER-RETURN-2")).thenReturn(true);
        service.reverse(order,2L,new BigDecimal("100000"));assertEquals(0,customer.getRewardPoints());assertEquals(11,customer.getRewardPointAdjustment());
        order.setId(11L);order.setSubtotal(new BigDecimal("100000"));order.setDiscountAmount(BigDecimal.ZERO);
        service.earned(order);assertEquals(0,customer.getRewardPoints());assertEquals(1,customer.getRewardPointAdjustment());
        order.setId(12L);service.earned(order);assertEquals(9,customer.getRewardPoints());assertEquals(0,customer.getRewardPointAdjustment());
    }
    @Test void redemptionCreatesOwnedOneUseVoucherAndRetryDoesNotDeductAgain() {
        service.redeem(7L,1L,"key");assertEquals(500,customer.getRewardPoints());
        var captor=org.mockito.ArgumentCaptor.forClass(Voucher.class);verify(vouchers).saveAndFlush(captor.capture());
        Voucher issued=captor.getValue();assertSame(customer,issued.getOwner());assertEquals(1,issued.getUsageLimit());assertFalse(issued.isRedeemable());
        assertEquals(LocalDateTime.now(clock).plusDays(30),issued.getEndDate());
        issued.setId(5L);when(vouchers.findByRedemptionKey("key")).thenReturn(Optional.of(issued));
        service.redeem(7L,1L,"key");assertEquals(500,customer.getRewardPoints());verify(ledger,times(1)).save(any());
    }
    @Test void insufficientPointsAndAnotherOwnersKeyAreRejected() {
        customer.setRewardPoints(499);assertThrows(BusinessException.class,()->service.redeem(7L,1L,"key"));verify(vouchers,never()).saveAndFlush(any());
        Customer other=new Customer();other.setId(99L);Voucher issued=new Voucher();issued.setOwner(other);
        when(vouchers.findByRedemptionKey("other")).thenReturn(Optional.of(issued));
        assertThrows(BusinessException.class,()->service.redeem(7L,1L,"other"));assertEquals(499,customer.getRewardPoints());
    }
    @Test void historyDefaultsToLastMonthInVietnamTimezone() {
        var pageable=org.springframework.data.domain.PageRequest.of(0,10);
        when(ledger.history(anyLong(),any(),any(),any())).thenReturn(org.springframework.data.domain.Page.empty());
        service.history(7L,null,null,pageable);
        verify(ledger).history(7L,LocalDateTime.parse("2026-09-09T17:00:00"),LocalDateTime.parse("2026-10-10T17:00:00"),pageable);
    }
}
