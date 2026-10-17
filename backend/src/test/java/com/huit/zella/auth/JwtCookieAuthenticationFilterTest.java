package com.huit.zella.auth;

import com.huit.zella.customer.CustomerRepository;
import com.huit.zella.staff.StaffRepository;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jwt.Jwt;

import jakarta.servlet.http.Cookie;
import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class JwtCookieAuthenticationFilterTest {
    @AfterEach void clearContext() { SecurityContextHolder.clearContext(); }

    @Test void validRequestLoadsAccountOnceAndUsesCurrentRoles() throws Exception {
        var f = new Fixture();
        f.run(4L, false);
        var authentication = SecurityContextHolder.getContext().getAuthentication();
        assertNotNull(authentication);
        assertEquals(1L, ((CurrentUser) authentication.getPrincipal()).id());
        assertEquals(List.of("ROLE_ADMIN"), authentication.getAuthorities().stream().map(Object::toString).toList());
        verify(f.users, times(1)).findById(1L);
        verify(f.sessions, times(1)).findById(9L);
        verify(f.tokens, never()).clearLoginCookie(any());
        assertTrue(f.continued);
    }

    @Test void oldOrMissingAuthVersionStillInvalidatesCookie() throws Exception {
        for (Long version : new Long[]{3L, null}) {
            var f = new Fixture();
            f.run(version, false);
            assertNull(SecurityContextHolder.getContext().getAuthentication());
            verify(f.users, times(1)).findById(1L);
            verify(f.tokens).clearLoginCookie(f.response);
            assertTrue(f.continued);
        }
    }

    @Test void disabledOrDeletedAccountStillDenied() {
        for (boolean deleted : new boolean[]{false, true}) {
            var f = new Fixture();
            if (deleted) when(f.users.findById(1L)).thenReturn(Optional.empty());
            else f.user.setActive(false);
            assertThrows(AccessDeniedException.class, () -> f.run(4L, false));
            assertNull(SecurityContextHolder.getContext().getAuthentication());
            verify(f.users, times(1)).findById(1L);
            verify(f.tokens).clearLoginCookie(f.response);
            assertFalse(f.continued);
        }
    }

    @Test void invalidSessionsRejectedBeforeLoadingAccount() throws Exception {
        for (String invalid : List.of("missing", "revoked", "expired", "owner", "role", "pending")) {
            var f = new Fixture();
            switch (invalid) {
                case "missing" -> when(f.sessions.findById(9L)).thenReturn(Optional.empty());
                case "revoked" -> f.session.setRevokedAt(Instant.now());
                case "expired" -> f.session.setExpiresAt(Instant.now().minusSeconds(1));
                case "owner" -> { var other = new User(); other.setId(2L); f.session.setUser(other); }
                case "role" -> f.session.setActiveRole("USER");
                case "pending" -> f.session.setRoleSelectionRequired(true);
            }
            f.run(4L, false);
            assertNull(SecurityContextHolder.getContext().getAuthentication(), invalid);
            verifyNoInteractions(f.users);
            verify(f.tokens).clearLoginCookie(f.response);
        }
    }

    @Test void removedRoleStillDenied() {
        var f = new Fixture();
        f.user.setRoles(new LinkedHashSet<>());
        assertThrows(AccessDeniedException.class, () -> f.run(4L, false));
        verify(f.users, times(1)).findById(1L);
        verify(f.tokens).clearLoginCookie(f.response);
        assertFalse(f.continued);
    }

    @Test void pendingSelectionStillRestrictedToRoleSelectionEndpoints() throws Exception {
        var f = new Fixture();
        f.session.setActiveRole(null);
        f.session.setRoleSelectionRequired(true);
        f.run(4L, true);
        assertEquals(403, f.response.getStatus());
        assertTrue(f.response.getContentAsString().contains("ROLE_SELECTION_REQUIRED"));
        assertFalse(f.continued);
        verify(f.users, times(1)).findById(1L);

        var allowed = new Fixture();
        allowed.path = "/api/v1/auth/me";
        allowed.session.setActiveRole(null);
        allowed.session.setRoleSelectionRequired(true);
        allowed.run(4L, true);
        assertTrue(allowed.continued);
        assertTrue(SecurityContextHolder.getContext().getAuthentication().getAuthorities().isEmpty());
    }

    static class Fixture {
        final UserRepository users = mock(UserRepository.class);
        final RefreshSessionRepository sessions = mock(RefreshSessionRepository.class);
        final JwtAccessTokenService tokens = mock(JwtAccessTokenService.class);
        final User user = new User();
        final RefreshSession session = new RefreshSession();
        final MockHttpServletResponse response = new MockHttpServletResponse();
        final JwtCookieAuthenticationFilter filter;
        String path = "/api/v1/product/cards";
        boolean continued;

        Fixture() {
            SecurityContextHolder.clearContext();
            user.setId(1L);
            user.setActive(true);
            user.setAuthVersion(4L);
            var role = new Role(); role.setRoleCode("ADMIN");
            user.setRoles(new LinkedHashSet<>(List.of(role)));
            session.setUser(user);
            session.setExpiresAt(Instant.now().plusSeconds(600));
            session.setActiveRole("ADMIN");
            when(users.findById(1L)).thenReturn(Optional.of(user));
            when(sessions.findById(9L)).thenReturn(Optional.of(session));
            var service = new UserService(users, mock(RoleRepository.class), mock(PasswordEncoder.class),
                    mock(CustomerRepository.class), sessions, mock(StaffRepository.class));
            filter = new JwtCookieAuthenticationFilter(tokens, service, sessions);
        }

        void run(Long version, boolean pending) throws Exception {
            var jwt = Jwt.withTokenValue("token").header("alg", "HS256")
                    .subject("test@example.com").claim("uid", 1L).claim("sid", 9L)
                    .claim("roleSelectionRequired", pending);
            if (!pending) jwt.claim("activeRole", "ADMIN");
            if (version != null) jwt.claim("authVersion", version);
            when(tokens.decode("token")).thenReturn(jwt.build());
            var request = new MockHttpServletRequest("GET", path);
            request.setCookies(new Cookie(JwtAccessTokenService.COOKIE_NAME, "token"));
            filter.doFilter(request, response, (req, res) -> continued = true);
        }
    }
}
