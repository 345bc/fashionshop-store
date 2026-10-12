package com.huit.zella.auth;

import jakarta.servlet.http.Cookie;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest(properties = "app.order.expiration.enabled=false") @Transactional
class RefreshTokenWorkflowTest {
    @Autowired WebApplicationContext context;
    @Autowired UserRepository users;
    @Autowired RoleRepository roles;
    @Autowired RefreshSessionRepository sessions;
    @Autowired PasswordEncoder passwords;
    MockMvc mvc;
    User user;

    @BeforeEach void setup() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        user = new User();
        String key = UUID.randomUUID().toString().substring(0, 12);
        user.setEmail("refresh-" + key + "@example.test"); user.setUserName("refresh-" + key);
        user.setPasswordHash(passwords.encode("TestPassword123!"));
        user.getRoles().add(roles.findByRoleCode("CUSTOMER").orElseThrow());
        users.saveAndFlush(user);
    }

    MvcResult login() throws Exception {
        return mvc.perform(post("/api/v1/auth/login").contentType("application/json")
                .content("{\"email\":\"" + user.getEmail() + "\",\"password\":\"TestPassword123!\"}"))
                .andExpect(status().isOk()).andReturn();
    }
    Cookie cookie(MvcResult result, String name) { return result.getResponse().getCookie(name); }
    RefreshSession session(Cookie token) { return sessions.findForUpdate(RefreshTokenService.hash(token.getValue())).orElseThrow(); }

    @Test void loginSetsHttpOnlyCookiesAndRefreshWorksWithoutAccessTokenButRequiresCsrf() throws Exception {
        var logged = login();
        Cookie refresh = cookie(logged, "REFRESH_TOKEN");
        assertNotNull(refresh); assertTrue(refresh.isHttpOnly()); assertEquals("Lax", refresh.getAttribute("SameSite"));
        assertEquals(7 * 24 * 3600, refresh.getMaxAge());
        assertNotEquals(refresh.getValue(), session(refresh).getTokenHash());
        mvc.perform(post("/api/v1/auth/refresh").cookie(refresh)).andExpect(status().isForbidden());
        var renewed = mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(refresh, new Cookie("ACCESS_TOKEN", "expired")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.id").value(user.getId())).andReturn();
        mvc.perform(get("/api/v1/auth/me").cookie(cookie(renewed, "ACCESS_TOKEN"))).andExpect(status().isOk());
    }

    @Test void rotationHandlesConcurrentRefreshAndRejectsLaterReplay() throws Exception {
        Cookie previous = cookie(login(), "REFRESH_TOKEN");
        var session = session(previous); session.setRotatedAt(Instant.now().minusSeconds(11));
        var first = mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(previous)).andExpect(status().isOk()).andReturn();
        Cookie current = cookie(first, "REFRESH_TOKEN"); assertNotEquals(previous.getValue(), current.getValue());
        var concurrent = mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(previous)).andExpect(status().isOk()).andReturn();
        assertEquals(current.getValue(), cookie(concurrent, "REFRESH_TOKEN").getValue());
        session.setRotatedAt(Instant.now().minusSeconds(11));
        mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(previous)).andExpect(status().isUnauthorized());
        assertNotNull(session.getRevokedAt());
        mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(current)).andExpect(status().isUnauthorized());
    }

    @Test void logoutRevokesRefreshEvenWhenAccessHasExpired() throws Exception {
        Cookie refresh = cookie(login(), "REFRESH_TOKEN");
        mvc.perform(post("/api/v1/auth/logout").with(csrf()).cookie(refresh, new Cookie("ACCESS_TOKEN", "expired")))
                .andExpect(status().isOk()).andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.cookie().maxAge("REFRESH_TOKEN", 0));
        assertNotNull(session(refresh).getRevokedAt());
        mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(refresh)).andExpect(status().isUnauthorized());
    }

    @Test void expiredDisabledAndPasswordChangedSessionsCannotRefresh() throws Exception {
        Cookie expired = cookie(login(), "REFRESH_TOKEN"); session(expired).setExpiresAt(Instant.now().minusSeconds(1));
        mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(expired)).andExpect(status().isUnauthorized());
        Cookie changed = cookie(login(), "REFRESH_TOKEN"); user.setPasswordHash(passwords.encode("ChangedPassword123!"));
        mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(changed)).andExpect(status().isUnauthorized());
        user.setPasswordHash(passwords.encode("TestPassword123!"));
        Cookie disabled = cookie(login(), "REFRESH_TOKEN"); user.setActive(false);
        mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(disabled)).andExpect(status().isUnauthorized());
    }

    @Test void accessUsesStableUserIdAndRefreshCannotExtendAbsoluteLifetime() throws Exception {
        var logged = login(); Cookie refresh = cookie(logged, "REFRESH_TOKEN");
        Instant deadline = session(refresh).getExpiresAt();
        user.setEmail("renamed-" + UUID.randomUUID() + "@example.test"); users.flush();
        mvc.perform(get("/api/v1/auth/me").cookie(cookie(logged, "ACCESS_TOKEN"))).andExpect(status().isOk());
        mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(refresh)).andExpect(status().isOk());
        assertEquals(deadline, session(refresh).getExpiresAt());
    }
}
