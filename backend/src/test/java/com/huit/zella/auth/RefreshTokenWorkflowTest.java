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
    @Autowired JwtAccessTokenService accessTokens;
    MockMvc mvc;
    User user;

    @BeforeEach void setup() {
        mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        user = new User();
        String key = UUID.randomUUID().toString().substring(0, 12);
        user.setEmail("refresh-" + key + "@example.test"); user.setUserName("refresh-" + key);
        user.setPasswordHash(passwords.encode("TestPassword123!"));
        user.getRoles().add(roles.findByRoleCode("USER").orElseThrow());
        users.saveAndFlush(user);
    }

    MvcResult login() throws Exception {
        return mvc.perform(post("/api/v1/auth/login").contentType("application/json")
                .content("{\"email\":\"" + user.getEmail() + "\",\"password\":\"TestPassword123!\"}"))
                .andExpect(status().isOk()).andReturn();
    }
    Cookie cookie(MvcResult result, String name) { return result.getResponse().getCookie(name); }
    RefreshSession session(Cookie token) { return sessions.findForUpdate(RefreshTokenService.hash(token.getValue())).orElseThrow(); }

    @Test void onlyAdminCanCreateRoleAndDuplicateCodesAreRejected() throws Exception {
        user.getRoles().clear();user.getRoles().add(roles.findByRoleCode("ADMIN").orElseThrow());users.flush();
        Cookie adminAccess=cookie(login(),"ACCESS_TOKEN");String code=("TEST_"+UUID.randomUUID().toString().replace("-","")).toUpperCase(java.util.Locale.ROOT);
        String body="{\"roleCode\":\""+code.toLowerCase()+"\",\"roleName\":\"Vai trò thử nghiệm\",\"description\":\"Kiểm tra API\"}";
        mvc.perform(post("/api/v1/role").with(csrf()).cookie(adminAccess).contentType("application/json").content(body))
          .andExpect(status().isOk()).andExpect(jsonPath("$.data.roleCode").value(code));
        mvc.perform(post("/api/v1/role").with(csrf()).cookie(adminAccess).contentType("application/json").content(body))
          .andExpect(status().isConflict());
        user.getRoles().clear();user.getRoles().add(roles.findByRoleCode("SALES").orElseThrow());users.flush();
        Cookie salesAccess=cookie(login(),"ACCESS_TOKEN");
        mvc.perform(post("/api/v1/role").with(csrf()).cookie(salesAccess).contentType("application/json").content(body))
          .andExpect(status().isForbidden());
    }

    @Test void adminLoginRejectsCustomerWithoutIssuingCookies() throws Exception {
        long count=sessions.count();
        var denied=mvc.perform(post("/api/v1/auth/admin/login").contentType("application/json")
                .content("{\"email\":\""+user.getEmail()+"\",\"password\":\"TestPassword123!\"}"))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ADMIN_ACCESS_DENIED")).andReturn();
        assertNull(cookie(denied,"ACCESS_TOKEN"));assertNull(cookie(denied,"REFRESH_TOKEN"));
        assertEquals(count,sessions.count());
        login(); // Customer login still works.
    }

    @Test void adminLoginAllowsBusinessRolesAndKeepsMultiRoleSelectionMandatory() throws Exception {
        user.getRoles().clear();user.getRoles().add(roles.findByRoleCode("SALES").orElseThrow());users.flush();
        var single=mvc.perform(post("/api/v1/auth/admin/login").contentType("application/json")
                .content("{\"email\":\""+user.getEmail()+"\",\"password\":\"TestPassword123!\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.activeRole").value("SALES")).andReturn();
        assertNotNull(cookie(single,"ACCESS_TOKEN"));
        user.getRoles().add(roles.findByRoleCode("ADMIN").orElseThrow());users.flush();
        var multi=mvc.perform(post("/api/v1/auth/admin/login").contentType("application/json")
                .cookie(new Cookie("ACCESS_TOKEN","expired"))
                .content("{\"email\":\""+user.getEmail()+"\",\"password\":\"TestPassword123!\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.roleSelectionRequired").value(true)).andReturn();
        mvc.perform(get("/api/v1/user").cookie(cookie(multi,"ACCESS_TOKEN")))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_SELECTION_REQUIRED"));
    }

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

    @Test void accessContainsOnlyActiveRoleAndSwitchDoesNotCombinePermissions() throws Exception {
        user.getRoles().clear();
        user.getRoles().add(roles.findByRoleCode("ADMIN").orElseThrow());
        user.getRoles().add(roles.findByRoleCode("SALES").orElseThrow());
        users.flush();
        var logged = login();
        var claims = accessTokens.decode(cookie(logged, "ACCESS_TOKEN").getValue());
        assertFalse(claims.hasClaim("roles"));
        assertNull(claims.getClaimAsString("activeRole"));
        assertEquals(true, claims.getClaim("roleSelectionRequired"));
        mvc.perform(get("/api/v1/user").cookie(cookie(logged,"ACCESS_TOKEN")))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_SELECTION_REQUIRED"));
        mvc.perform(get("/api/v1/product").cookie(cookie(logged,"ACCESS_TOKEN")))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_SELECTION_REQUIRED"));
        mvc.perform(get("/api/v1/auth/me").cookie(cookie(logged,"ACCESS_TOKEN")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.roleSelectionRequired").value(true));
        var pendingRefresh=mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(cookie(logged,"REFRESH_TOKEN")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.roleSelectionRequired").value(true)).andReturn();
        mvc.perform(get("/api/v1/customers").cookie(cookie(pendingRefresh,"ACCESS_TOKEN")))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROLE_SELECTION_REQUIRED"));
        mvc.perform(post("/api/v1/auth/select-role").with(csrf()).cookie(cookie(logged, "ACCESS_TOKEN"))
                .contentType("application/json").content("{\"role\":\"WAREHOUSE\"}"))
                .andExpect(status().isForbidden());
        var switched = mvc.perform(post("/api/v1/auth/select-role").with(csrf())
                .cookie(cookie(logged, "ACCESS_TOKEN"), cookie(logged, "REFRESH_TOKEN"))
                .contentType("application/json").content("{\"role\":\"SALES\"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.activeRole").value("SALES"))
                .andExpect(jsonPath("$.data.roles.length()").value(2)).andReturn();
        mvc.perform(get("/api/v1/user").cookie(cookie(switched, "ACCESS_TOKEN")))
                .andExpect(status().isForbidden());
        var renewed = mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(cookie(switched, "REFRESH_TOKEN")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.activeRole").value("SALES")).andReturn();
        mvc.perform(get("/api/v1/inventory").cookie(cookie(renewed, "ACCESS_TOKEN")))
                .andExpect(status().isForbidden());
    }

    @Test void pendingSessionCannotBeReplayedAfterSelectionOrLogout() throws Exception {
        user.getRoles().add(roles.findByRoleCode("SALES").orElseThrow()); users.flush();
        var logged=login();Cookie pending=cookie(logged,"ACCESS_TOKEN");
        var selected=mvc.perform(post("/api/v1/auth/select-role").with(csrf()).cookie(pending)
                .contentType("application/json").content("{\"role\":\"SALES\"}"))
                .andExpect(status().isOk()).andReturn();
        mvc.perform(post("/api/v1/auth/select-role").with(csrf()).cookie(pending)
                .contentType("application/json").content("{\"role\":\"USER\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/v1/auth/logout").with(csrf()).cookie(cookie(selected,"ACCESS_TOKEN")))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/auth/me").cookie(cookie(selected,"ACCESS_TOKEN")))
                .andExpect(status().isUnauthorized());
        var another=login();
        mvc.perform(post("/api/v1/auth/logout").with(csrf()).cookie(cookie(another,"ACCESS_TOKEN")))
                .andExpect(status().isOk());
        mvc.perform(post("/api/v1/auth/select-role").with(csrf()).cookie(cookie(another,"ACCESS_TOKEN"))
                .contentType("application/json").content("{\"role\":\"SALES\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test void revokingActiveRoleBlocksAccessAndRefresh() throws Exception {
        var logged = login();
        user.getRoles().clear();
        user.getRoles().add(roles.findByRoleCode("SALES").orElseThrow());
        users.flush();
        mvc.perform(get("/api/v1/auth/me").cookie(cookie(logged, "ACCESS_TOKEN")))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(cookie(logged, "REFRESH_TOKEN")))
                .andExpect(status().isUnauthorized());
    }

    @Test void businessModulesUseActiveRoleEvenWhenAccountHasEveryRole() throws Exception {
        user.getRoles().clear();
        for (var role : com.huit.zella.enums.RoleEnum.values()) {
            user.getRoles().add(roles.findByRoleCode(role.name()).orElseThrow());
        }
        users.flush();
        Cookie access = cookie(login(), "ACCESS_TOKEN");
        for (String role : new String[]{"ADMIN", "SALES", "WAREHOUSE", "CUSTOMER_SUPPORT", "MARKETING", "USER"}) {
            var selected = mvc.perform(post("/api/v1/auth/select-role").with(csrf()).cookie(access)
                    .contentType("application/json").content("{\"role\":\"" + role + "\"}"))
                    .andExpect(status().isOk()).andReturn();
            Cookie active = cookie(selected, "ACCESS_TOKEN");
            access=active;
            boolean admin = role.equals("ADMIN");
            mvc.perform(get("/api/v1/user").cookie(active)).andExpect(status().is(admin ? 200 : 403));
            mvc.perform(get("/api/v1/inventory").cookie(active))
                    .andExpect(status().is(admin || role.equals("WAREHOUSE") ? 200 : 403));
            mvc.perform(get("/api/v1/campaigns/voucher").cookie(active))
                    .andExpect(status().is(admin || role.equals("MARKETING") ? 200 : 403));
            mvc.perform(get("/api/v1/customers").cookie(active))
                    .andExpect(status().is(admin || role.equals("SALES") || role.equals("CUSTOMER_SUPPORT") ? 200 : 403));
            if (!admin) {
                mvc.perform(post("/api/v1/inventory/adjustments").with(csrf()).cookie(active)
                        .contentType("application/json").content("{\"reason\":\"test\",\"items\":[{\"variantId\":1,\"expectedQuantity\":0,\"countedQuantity\":0}]}"))
                        .andExpect(status().isForbidden());
                mvc.perform(post("/api/v1/order/1/refunded").with(csrf()).cookie(active)
                        .contentType("application/json").content("{\"note\":\"test\"}"))
                        .andExpect(status().isForbidden());
            }
        }
    }
}
