package com.huit.zella.user;

import com.huit.zella.auth.UserService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.context.annotation.*;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class UserWriteAuthorizationTest {
    @Configuration
    @EnableMethodSecurity
    static class Config {
        @Bean UserService users() { return mock(UserService.class); }
        @Bean UserController controller(UserService users) { return new UserController(users); }
    }

    @Test void employeeCannotCreateEditOrDeleteUsersWhileAdminCan() {
        try (var context = new AnnotationConfigApplicationContext(Config.class)) {
            var controller = context.getBean(UserController.class);
            var users = context.getBean(UserService.class);
            authenticate("SALES");
            assertThrows(AccessDeniedException.class, () -> controller.create(null));
            assertThrows(AccessDeniedException.class, () -> controller.update(1L, null));
            assertThrows(AccessDeniedException.class, () -> controller.deleteUser(1L));
            verifyNoInteractions(users);
            authenticate("ADMIN");
            controller.create(null); controller.update(1L, null); controller.deleteUser(1L);
            verify(users).createUser(null); verify(users).update(1L, null); verify(users).deleteUser(1L);
        } finally { SecurityContextHolder.clearContext(); }
    }

    private void authenticate(String role) {
        SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
                "test", null, List.of(new SimpleGrantedAuthority("ROLE_" + role))));
    }
}
