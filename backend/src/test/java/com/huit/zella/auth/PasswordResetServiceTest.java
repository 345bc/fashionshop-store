package com.huit.zella.auth;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.mail.EmailQueue;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.password.PasswordEncoder;
import java.time.Instant;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class PasswordResetServiceTest {
    final UserRepository users = mock(UserRepository.class);
    final PasswordResetRepository resets = mock(PasswordResetRepository.class);
    final PasswordEncoder encoder = mock(PasswordEncoder.class);
    final EmailQueue emails = mock(EmailQueue.class);
    final PasswordResetService service = new PasswordResetService(users, resets, encoder, emails, "https://shop.example");
    User user;
    PasswordReset reset;
    final String token = "a".repeat(43);

    @BeforeEach void setup() {
        user = new User(); user.setId(1L); user.setEmail("buyer@gmail.com"); user.setAuthVersion(4);
        reset = new PasswordReset(); reset.setUserId(1L); reset.setTokenHash(PasswordResetService.hash(token));
        reset.setAuthVersion(4); reset.setCreatedAt(Instant.now().minusSeconds(61)); reset.setExpiresAt(Instant.now().plusSeconds(900));
        when(emails.enabled()).thenReturn(true);
        when(users.lockByEmail("buyer@gmail.com")).thenReturn(Optional.of(user));
        when(users.lockById(1L)).thenReturn(Optional.of(user));
        when(resets.findUserId(reset.getTokenHash())).thenReturn(Optional.of(1L));
        when(resets.findById(1L)).thenReturn(Optional.of(reset));
    }

    @Test void resetLinkUsesRandomSecretAndStoresOnlyHash() {
        service.request(" BUYER@gmail.com ");
        ArgumentCaptor<String> body = ArgumentCaptor.forClass(String.class);
        verify(emails).enqueue(eq(user.getEmail()), anyString(), body.capture(), eq(reset.getExpiresAt()));
        String secret = body.getValue().split("#token=")[1].split("\n")[0];
        assertTrue(secret.matches("[A-Za-z0-9_-]{43}"));
        assertEquals(PasswordResetService.hash(secret), reset.getTokenHash());
        assertNotEquals(secret, reset.getTokenHash());
        assertTrue(body.getValue().contains("https://shop.example/reset-password#token="));
    }

    @Test void unknownOrInactiveEmailQueuesNothing() {
        service.request("unknown@gmail.com");
        user.setActive(false);
        service.request(user.getEmail());
        verify(emails, never()).enqueue(any(), any(), any(), any());
    }

    @Test void disabledMailFailsForAllAddresses() {
        when(emails.enabled()).thenReturn(false);
        assertThrows(BusinessException.class, () -> service.request("unknown@gmail.com"));
        verifyNoInteractions(users);
    }

    @Test void repeatedRequestsRespectCooldown() {
        reset.setCreatedAt(Instant.now());
        service.request(user.getEmail());
        verify(resets, never()).save(any());
        verify(emails, never()).enqueue(any(), any(), any(), any());
    }

    @Test void successfulResetChangesHashInvalidatesSessionsAndConsumesToken() {
        when(encoder.encode("NewPassword123")).thenReturn("new-bcrypt-hash");
        service.reset(token, "NewPassword123");
        assertEquals("new-bcrypt-hash", user.getPasswordHash());
        assertEquals(5, user.getAuthVersion());
        verify(resets).delete(reset);
        // Replayed token is also rejected by authVersion even before a delete is observed.
        assertThrows(BusinessException.class, () -> service.reset(token, "OtherPassword123"));
    }

    @Test void expiredTokenCannotChangePassword() {
        reset.setExpiresAt(Instant.now().minusSeconds(1));
        assertThrows(BusinessException.class, () -> service.reset(token, "NewPassword123"));
        verifyNoInteractions(encoder);
    }

    @Test void replacedTokenCannotChangePassword() {
        reset.setTokenHash(PasswordResetService.hash("b".repeat(43)));
        assertThrows(BusinessException.class, () -> service.reset(token, "NewPassword123"));
        verifyNoInteractions(encoder);
    }

    @Test void inactiveAccountAndChangedAuthVersionRejectToken() {
        user.setActive(false);
        assertThrows(BusinessException.class, () -> service.reset(token, "NewPassword123"));
        user.setActive(true); user.setAuthVersion(5);
        assertThrows(BusinessException.class, () -> service.reset(token, "NewPassword123"));
        verifyNoInteractions(encoder);
    }

    @Test void invalidTokenAndOversizedUtf8PasswordAreRejected() {
        assertThrows(BusinessException.class, () -> service.reset("unknown", "NewPassword123"));
        assertThrows(BusinessException.class, () -> service.reset(token, "ấ".repeat(30)));
        verifyNoInteractions(encoder);
    }
}
