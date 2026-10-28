package com.huit.zella.voucher;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.customer.Customer;
import com.huit.zella.customer.CustomerRepository;
import com.huit.zella.mail.EmailQueue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.*;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class VoucherEmailServiceTest {
    private final VoucherRepository vouchers = mock(VoucherRepository.class);
    private final CustomerRepository customers = mock(CustomerRepository.class);
    private final VoucherEmailRecipientRepository recipients = mock(VoucherEmailRecipientRepository.class);
    private final EmailQueue queue = mock(EmailQueue.class);
    private final VoucherEmailBatchWriter batch = mock(VoucherEmailBatchWriter.class);
    private final Instant now = Instant.parse("2026-10-21T03:00:00Z");
    private final VoucherEmailService service = new VoucherEmailService(vouchers, customers, recipients,
            queue, batch, Clock.fixed(now, ZoneOffset.UTC), 3000);
    private final Set<String> tiers = Set.of("GOLD", "SILVER");
    private final Set<String> queued = new HashSet<>();
    private Voucher voucher;
    private List<CustomerRepository.VoucherEmailRecipient> audience;

    private record Contact(Long id, String fullName, String email, String membershipTier)
            implements CustomerRepository.VoucherEmailRecipient {
        public Long getId() { return id; }
        public String getFullName() { return fullName; }
        public String getEmail() { return email; }
        public String getMembershipTier() { return membershipTier; }
    }

    @BeforeEach void setup() {
        voucher = new Voucher(); voucher.setId(1L); voucher.setCode("GOLD20"); voucher.setName("Ưu đãi thành viên");
        voucher.setDiscountType("PERCENT"); voucher.setDiscountValue(new BigDecimal("20"));
        voucher.setMinOrderAmount(new BigDecimal("300000")); voucher.setDiscountAmount(new BigDecimal("100000"));
        voucher.setStartDate(LocalDateTime.ofInstant(now.minusSeconds(3600), ZoneOffset.UTC));
        voucher.setEndDate(LocalDateTime.ofInstant(now.plusSeconds(86400), ZoneOffset.UTC));
        voucher.setUsageLimit(10); voucher.setUsedCount(2);
        audience = new ArrayList<>(List.of(new Contact(1L, "An", "a@gmail.com", "GOLD"),
                new Contact(2L, "Bình", "b@gmail.com", "SILVER")));
        when(queue.enabled()).thenReturn(true);
        when(vouchers.findById(1L)).thenReturn(Optional.of(voucher));
        when(vouchers.lock(1L)).thenReturn(Optional.of(voucher));
        when(recipients.queuedEmails(1L)).thenAnswer(invocation -> new ArrayList<>(queued));
        doAnswer(invocation -> {
            List<VoucherEmailBatchWriter.Message> messages = invocation.getArgument(2);
            messages.forEach(message -> queued.add(message.email()));
            return null;
        }).when(batch).enqueue(any(), any(), anyList());
        when(customers.voucherEmailRecipients(anySet(), any())).thenAnswer(invocation ->
                new SliceImpl<>(audience.stream().filter(c -> ((Set<?>) invocation.getArgument(0)).contains(c.getMembershipTier())).toList()));
    }

    @Test void previewFiltersInvalidEmailsDeduplicatesAndExcludesPreviouslyQueued() {
        audience.add(new Contact(3L, "Trùng", " A@gmail.com ", "SILVER"));
        audience.add(new Contact(4L, "Lỗi", "invalid-email", "GOLD"));
        audience.add(new Contact(5L, "Trống", null, "GOLD"));
        audience.add(new Contact(6L, "Không thuộc nhóm", "other@gmail.com", "STANDARD"));
        queued.add("b@gmail.com");
        var result = service.preview(1L, tiers);
        assertEquals(2, result.eligible()); assertEquals(1, result.alreadyQueued());
        assertEquals(2, result.invalidEmails()); assertEquals(1, result.toQueue());
        assertEquals("a@gmail.com", result.sample().getFirst().email());
        assertEquals(8, result.remainingUses());
        verify(customers).voucherEmailRecipients(eq(tiers), any());
        verifyNoInteractions(batch);
    }

    @Test void sendQueuesIndividualMailWithSpacingExpirationAndPersistentDeduplication() {
        var preview = service.preview(1L, tiers);
        var result = service.send(1L, tiers, preview.audienceKey());
        assertEquals(2, result.queued());
        verify(vouchers).lock(1L);
        verify(batch).enqueue(eq(1L), eq(now), argThat(messages -> {
            var first = messages.getFirst(); var second = messages.getLast();
            assertEquals("a@gmail.com", first.email()); assertEquals("b@gmail.com", second.email());
            assertTrue(first.subject().contains("GOLD20"));
            assertTrue(first.body().contains("20%")); assertTrue(first.body().contains("100.000"));
            assertTrue(first.body().contains("300.000")); assertTrue(first.body().contains("22/10/2026 10:00"));
            assertEquals(now, first.scheduledAt()); assertEquals(now.plusSeconds(3), second.scheduledAt());
            assertEquals(now.plusSeconds(86400), first.expiresAt());
            return messages.size() == 2;
        }));
        assertEquals(Set.of("a@gmail.com", "b@gmail.com"), queued);
        assertEquals(0, service.preview(1L, tiers).toQueue());
        var fresh = service.preview(1L, tiers);
        assertEquals(0, service.send(1L, tiers, fresh.audienceKey()).queued());
        verify(batch, times(1)).enqueue(any(), any(), argThat(messages -> !messages.isEmpty()));
    }

    @Test void changingTierSelectionInvalidatesPreview() {
        var preview = service.preview(1L, tiers);
        assertThrows(BusinessException.class, () -> service.send(1L, Set.of("GOLD"), preview.audienceKey()));
        verifyNoInteractions(batch);
    }

    @Test void changedAudienceMustBePreviewedAgain() {
        var preview = service.preview(1L, tiers);
        audience.add(new Contact(3L, "Mới", "new@gmail.com", "GOLD"));
        assertThrows(BusinessException.class, () -> service.send(1L, tiers, preview.audienceKey()));
        verifyNoInteractions(batch);
    }

    @Test void changedVoucherTermsMustBePreviewedAgain() {
        var preview = service.preview(1L, tiers);
        voucher.setDiscountValue(new BigDecimal("10"));
        assertThrows(BusinessException.class, () -> service.send(1L, tiers, preview.audienceKey()));
        verifyNoInteractions(batch);
    }

    @Test void unknownTierAndDisabledMailCannotSend() {
        assertThrows(BusinessException.class, () -> service.preview(1L, Set.of("ADMIN")));
        assertThrows(BusinessException.class, () -> service.preview(1L, Set.of()));
        when(queue.enabled()).thenReturn(false);
        assertThrows(BusinessException.class, () -> service.preview(1L, tiers));
        verifyNoInteractions(vouchers, customers, recipients);
    }

    @Test void inactiveExpiredFutureAndExhaustedVouchersCannotBeSent() {
        voucher.setActive(false);
        assertThrows(BusinessException.class, () -> service.preview(1L, tiers));
        voucher.setActive(true); voucher.setEndDate(LocalDateTime.ofInstant(now, ZoneOffset.UTC));
        assertThrows(BusinessException.class, () -> service.preview(1L, tiers));
        voucher.setEndDate(LocalDateTime.ofInstant(now.plusSeconds(86400), ZoneOffset.UTC));
        voucher.setStartDate(LocalDateTime.ofInstant(now.plusSeconds(1), ZoneOffset.UTC));
        assertThrows(BusinessException.class, () -> service.preview(1L, tiers));
        voucher.setStartDate(LocalDateTime.ofInstant(now.minusSeconds(1), ZoneOffset.UTC));
        voucher.setUsedCount(10);
        assertThrows(BusinessException.class, () -> service.preview(1L, tiers));
        verifyNoInteractions(customers, recipients);
    }

    @Test void rewardTemplatesAndPrivateCodesCannotBeMassSent() {
        voucher.setRedeemable(true);
        assertThrows(BusinessException.class, () -> service.preview(1L, tiers));
        voucher.setRedeemable(false); voucher.setOwner(new Customer());
        assertThrows(BusinessException.class, () -> service.preview(1L, tiers));
        voucher.setOwner(null); voucher.setSourceRewardId(2L);
        assertThrows(BusinessException.class, () -> service.preview(1L, tiers));
        verifyNoInteractions(customers, recipients);
    }

    @Test void noRecipientIsQueuedBeyondExpiration() {
        voucher.setEndDate(LocalDateTime.ofInstant(now.plusSeconds(2), ZoneOffset.UTC));
        var preview = service.preview(1L, tiers);
        assertThrows(BusinessException.class, () -> service.send(1L, tiers, preview.audienceKey()));
        verifyNoInteractions(batch);
    }

    @Test void previewHasAccurateCountsButOnlyTwentySampleRows() {
        audience.clear();
        for (long id = 1; id <= 30; id++) audience.add(new Contact(id, "Khách " + id, "user" + id + "@gmail.com", "GOLD"));
        var preview = service.preview(1L, tiers);
        assertEquals(30, preview.toQueue()); assertEquals(20, preview.sample().size());
        assertTrue(preview.emailBody().contains("Mã voucher: GOLD20"));
    }

    @Test void recipientQueryReadsSubsequentPages() {
        when(customers.voucherEmailRecipients(eq(tiers), eq(PageRequest.of(0, 500))))
                .thenReturn(new SliceImpl<>(List.of(audience.getFirst()), PageRequest.of(0, 500), true));
        when(customers.voucherEmailRecipients(eq(tiers), eq(PageRequest.of(1, 500))))
                .thenReturn(new SliceImpl<>(List.of(audience.getLast()), PageRequest.of(1, 500), false));
        assertEquals(2, service.preview(1L, tiers).toQueue());
        verify(customers).voucherEmailRecipients(tiers, PageRequest.of(1, 500));
    }
}
