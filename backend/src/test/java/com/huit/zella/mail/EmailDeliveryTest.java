package com.huit.zella.mail;

import org.junit.jupiter.api.Test;
import org.springframework.mail.*;
import org.springframework.mail.javamail.JavaMailSender;
import java.time.Instant;
import java.util.Optional;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class EmailDeliveryTest {
    final EmailOutboxRepository repository = mock(EmailOutboxRepository.class);
    final JavaMailSender sender = mock(JavaMailSender.class);
    final EmailDelivery delivery = new EmailDelivery(repository, sender, "sender@gmail.com");

    QueuedEmail email() {
        QueuedEmail email = new QueuedEmail(); email.setId(1L); email.setRecipient("buyer@example.com");
        email.setSubject("Đặt lại mật khẩu"); email.setBody("Secret link");
        email.setNextAttemptAt(Instant.now().minusSeconds(1));
        when(repository.lock(1L)).thenReturn(Optional.of(email));
        return email;
    }

    @Test void sendsAndRemovesDeliveredEmail() {
        QueuedEmail email = email();
        delivery.deliver(1L);
        var captor = org.mockito.ArgumentCaptor.forClass(SimpleMailMessage.class);
        verify(sender).send(captor.capture());
        assertEquals("sender@gmail.com", captor.getValue().getFrom());
        assertArrayEquals(new String[]{email.getRecipient()}, captor.getValue().getTo());
        assertEquals(email.getBody(), captor.getValue().getText());
        verify(repository).delete(email);
    }

    @Test void expiredResetEmailIsDiscardedWithoutSending() {
        QueuedEmail email = email(); email.setExpiresAt(Instant.now().minusSeconds(1));
        delivery.deliver(1L);
        verifyNoInteractions(sender);
        verify(repository).delete(email);
    }

    @Test void smtpFailureSchedulesRetryWithoutDeletingMessage() {
        QueuedEmail email = email();
        doThrow(new MailAuthenticationException("bad credentials")).when(sender).send(any(SimpleMailMessage.class));
        delivery.deliver(1L);
        assertEquals(1, email.getAttempts());
        assertTrue(email.getNextAttemptAt().isAfter(Instant.now()));
        verify(repository, never()).delete(any());
    }

    @Test void terminalFailureClearsSensitiveContentAndStopsRetrying() {
        QueuedEmail email = email(); email.setAttempts(7);
        doThrow(new MailSendException("offline")).when(sender).send(any(SimpleMailMessage.class));
        delivery.deliver(1L);
        assertEquals(8, email.getAttempts()); assertEquals("", email.getBody());
        clearInvocations(sender);
        delivery.deliver(1L);
        verifyNoInteractions(sender);
    }

    @Test void futureRetryIsNotSentTwice() {
        QueuedEmail email = email(); email.setNextAttemptAt(Instant.now().plusSeconds(60));
        delivery.deliver(1L);
        verifyNoInteractions(sender);
    }

    @Test void htmlEmailIsSentWithUtf8PlainTextAlternativeAndBrandName() throws Exception {
        QueuedEmail email = email(); email.setHtmlBody("<html><body><h1>Đơn hàng đã hủy</h1></body></html>");
        var mime = new jakarta.mail.internet.MimeMessage(jakarta.mail.Session.getInstance(new java.util.Properties()));
        when(sender.createMimeMessage()).thenReturn(mime);
        delivery.deliver(1L);
        verify(sender).send(mime);
        mime.saveChanges();
        assertEquals(email.getSubject(), mime.getSubject());
        var from = (jakarta.mail.internet.InternetAddress) mime.getFrom()[0];
        assertEquals("ZELLA", from.getPersonal()); assertEquals("sender@gmail.com", from.getAddress());
        assertTrue(hasText(mime, "text/plain", "Secret link"));
        assertTrue(hasText(mime, "text/html", "Đơn hàng đã hủy"));
        verify(repository).delete(email);
    }

    @Test void htmlDeliveryFailureClearsBothBodiesAtRetryLimit() {
        QueuedEmail email = email(); email.setAttempts(7); email.setHtmlBody("<p>Personal order information</p>");
        var mime = new jakarta.mail.internet.MimeMessage(jakarta.mail.Session.getInstance(new java.util.Properties()));
        when(sender.createMimeMessage()).thenReturn(mime);
        doThrow(new MailSendException("offline")).when(sender).send(mime);
        delivery.deliver(1L);
        assertEquals(8, email.getAttempts()); assertEquals("", email.getBody()); assertNull(email.getHtmlBody());
        verify(repository, never()).delete(any());
    }

    private boolean hasText(jakarta.mail.Part part, String mimeType, String expected) throws Exception {
        if (part.isMimeType(mimeType)) return part.getContent().toString().contains(expected);
        if (part.getContent() instanceof jakarta.mail.Multipart multipart) {
            for (int index = 0; index < multipart.getCount(); index++)
                if (hasText(multipart.getBodyPart(index), mimeType, expected)) return true;
        }
        return false;
    }
}
