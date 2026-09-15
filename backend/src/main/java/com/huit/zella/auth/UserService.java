package com.huit.zella.auth;

import com.huit.zella.common.exception.BusinessException;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.core.oidc.user.OidcUser;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class UserService {
    UserRepository user_repository;
    RoleRepository role_repository;

    @Transactional(readOnly = true)
    public CurrentUser requireByEmail(String email) {
        User user = user_repository.findByEmailIgnoreCase(normalizeEmail(email))
                .orElseThrow(() -> new BusinessException(HttpStatus.UNAUTHORIZED,
                        "USER_NOT_FOUND", "Tài khoản chưa được cấp quyền"));
        if (!user.isActive()) {
            throw new BusinessException(HttpStatus.FORBIDDEN, "USER_DISABLED", "Tài khoản đã bị khóa");
        }
        return toCurrentUser(user);
    }

    @Transactional
    public CurrentUser authenticate(String email, String rawPassword, PasswordEncoder passwordEncoder) {
        User user = user_repository.findByEmailIgnoreCase(normalizeEmail(email))
                .orElseThrow(this::invalidCredentials);
        if (!user.isActive()) {
            throw new BusinessException(HttpStatus.FORBIDDEN, "USER_DISABLED", "Tài khoản đã bị khóa");
        }
        if (user.getPassword_hash() == null || !passwordEncoder.matches(rawPassword, user.getPassword_hash())) {
            throw invalidCredentials();
        }
        return toCurrentUser(user);
    }

//    @Transactional
//    public CurrentUser register(String email, String rawPassword, PasswordEncoder passwordEncoder) {
//        User user = user_repository.findByEmailIgnoreCase(normalizeEmail(email))
//                .orElseThrow(this::invalidCredentials);
//        if (!user.is_active()) {
//            throw new BusinessException(HttpStatus.FORBIDDEN, "USER_DISABLED", "Tài khoản đã bị khóa");
//        }
//        if (user.getPassword_hash() == null || !passwordEncoder.matches(rawPassword, user.getPassword_hash())) {
//            throw invalidCredentials();
//        }
//        return toCurrentUser(user);
//    }


    @Transactional(readOnly = true)
    public CurrentUser current(Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new BusinessException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "Bạn chưa đăng nhập");
        }
        if (authentication.getPrincipal() instanceof CurrentUser currentUser) {
            return currentUser;
        }
//        if (authentication.getPrincipal() instanceof OidcUser oidcUser) {
//            return requireByEmail(oidcEmail(oidcUser));
//        }
        return requireByEmail(authentication.getName());
    }


    String normalizeEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "EMAIL_REQUIRED", "Email là bắt buộc");
        }
        return email.trim().toLowerCase(Locale.ROOT);
    }

    CurrentUser toCurrentUser(User user) {
        List<String> roles = user.getRoles().stream().map(Role::getRoleName).sorted().toList();
        return new CurrentUser(user.getId(), user.getEmail(), user.getUsername(), roles);
    }

    BusinessException invalidCredentials() {
        return new BusinessException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS",
                "Email hoặc mật khẩu không đúng");
    }

}
