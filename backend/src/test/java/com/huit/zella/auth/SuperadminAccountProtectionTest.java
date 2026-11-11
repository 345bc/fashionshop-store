package com.huit.zella.auth;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.customer.CustomerRepository;
import com.huit.zella.enums.RoleEnum;
import com.huit.zella.staff.StaffRepository;
import com.huit.zella.user.CreateUserRequest;
import com.huit.zella.user.UpdateUserRequest;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class SuperadminAccountProtectionTest {
    private final UserRepository users = mock(UserRepository.class);
    private final UserService service = new UserService(users, mock(RoleRepository.class),
            mock(PasswordEncoder.class), mock(CustomerRepository.class),
            mock(RefreshSessionRepository.class), mock(StaffRepository.class));

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void adminCannotGrantSuperadminOrModifyItsAccounts() {
        authenticate("ADMIN");
        var account = account(1L, RoleEnum.ADMIN);
        var superadmin = account(2L, RoleEnum.SUPERADMIN);
        when(users.findById(1L)).thenReturn(Optional.of(account));
        when(users.findById(2L)).thenReturn(Optional.of(superadmin));
        when(users.lockById(2L)).thenReturn(Optional.of(superadmin));

        assertError("SUPERADMIN_REQUIRED", () -> service.createUser(new CreateUserRequest(
                "tester", "password", "tester@example.test", Set.of(RoleEnum.SUPERADMIN))));
        assertError("SUPERADMIN_REQUIRED", () -> service.update(1L, update(true, RoleEnum.SUPERADMIN)));
        assertError("SUPERADMIN_REQUIRED", () -> service.update(2L, update(true, RoleEnum.SUPERADMIN)));
        assertError("SUPERADMIN_REQUIRED", () -> service.update(2L, update(false, RoleEnum.ADMIN)));
        assertError("SUPERADMIN_REQUIRED", () -> service.deleteUser(2L));
    }

    @Test
    void lastActiveSuperadminCannotBeDisabledOrDemoted() {
        authenticate("SUPERADMIN");
        var superadmin = account(2L, RoleEnum.SUPERADMIN);
        when(users.findById(2L)).thenReturn(Optional.of(superadmin));
        when(users.lockById(2L)).thenReturn(Optional.of(superadmin));
        when(users.lockAccounts()).thenReturn(List.of(superadmin));

        assertError("LAST_SUPERADMIN", () -> service.update(2L, update(false, RoleEnum.SUPERADMIN)));
        assertError("LAST_SUPERADMIN", () -> service.update(2L, update(true, RoleEnum.ADMIN)));
        assertError("ADMIN_DELETE_BLOCKED", () -> service.deleteUser(2L));
    }

    private void authenticate(String role) {
        SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated(
                "tester", null, List.of(new SimpleGrantedAuthority("ROLE_" + role))));
    }

    private User account(long id, RoleEnum role) {
        var user = new User();
        user.setId(id);
        user.setActive(true);
        user.setRoles(Set.of(new Role(id, role.name(), role.name(), null)));
        return user;
    }

    private UpdateUserRequest update(boolean active, RoleEnum role) {
        return new UpdateUserRequest("tester", "new-password", "tester@example.test", Set.of(role), active);
    }

    private void assertError(String code, Runnable action) {
        assertEquals(code, assertThrows(BusinessException.class, action::run).getCode());
    }
}
