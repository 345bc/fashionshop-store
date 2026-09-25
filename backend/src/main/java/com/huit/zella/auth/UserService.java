package com.huit.zella.auth;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.user.CreateUserRequest;
import com.huit.zella.user.UpdateUserRequest;
import com.huit.zella.user.UserResponse;
import jakarta.persistence.EntityNotFoundException;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.huit.zella.enums.RoleEnum;

import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class UserService {
    UserRepository user_repository;
    RoleRepository role_repository;
    PasswordEncoder passwordEncoder;

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
        if (user.getPasswordHash() == null || !passwordEncoder.matches(rawPassword, user.getPasswordHash())) {
            throw invalidCredentials();
        }
        CurrentUser currentUser = toCurrentUser(user);
        if (currentUser.roles().isEmpty()) {
            throw new BusinessException(HttpStatus.FORBIDDEN, "ROLE_NOT_ASSIGNED",
                    "Tài khoản chưa được gán vai trò");
        }
        return currentUser;
    }

    @Transactional
    public CurrentUser register(String email,  String userName, String rawPassword, PasswordEncoder passwordEncoder) {
        if (user_repository.findByEmailIgnoreCase(normalizeEmail(email)).isPresent()
                || user_repository.findByUserNameIgnoreCase(normalizeUserName(userName)).isPresent()) {
            throw informationAlreadyExists();
        }

        Role userRole = role_repository.findByRoleCode(RoleEnum.USER.name())
                .orElseThrow(() -> new BusinessException(
                        HttpStatus.INTERNAL_SERVER_ERROR,
                        "ROLE_NOT_FOUND",
                        "Lỗi: Không tìm thấy Role USER trong DB!"
                ));
        Set<Role> roles = new HashSet<>();
        roles.add(userRole);

        User user = new User();
        user.setUserName(userName);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(rawPassword));
        user.setActive(true);
        user.setRoles(roles);

        user = user_repository.save(user);

        return toCurrentUser(user);
    }

    @Transactional
    public UserResponse createUser (CreateUserRequest req){
        if (user_repository.findByEmailIgnoreCase(normalizeEmail(req.email())).isPresent()
                || user_repository.findByUserNameIgnoreCase(normalizeUserName(req.username())).isPresent()) {
            throw informationAlreadyExists();
        }

        Set<Role> roles = new HashSet<>();

        for (RoleEnum role : req.roles()) {
            Role dbRole = role_repository.findByRoleCode(role.name())
                    .orElseThrow(() -> new BusinessException(
                            HttpStatus.BAD_REQUEST,
                            "ROLE_NOT_FOUND",
                            "Lỗi: Không tìm thấy Role " + role.name() + " trong hệ thống!"
                    ));

            roles.add(dbRole);
        }

        User user = new User();
        user.setUserName(req.username());
        user.setEmail(req.email());
        user.setPasswordHash(passwordEncoder.encode(req.password()));
        user.setRoles(roles);

        user = user_repository.save(user);

        return UserResponse.createUserResponse(user);
    }

    @Transactional(readOnly = true)
    public Page<UserResponse> listUser(String query, String role, Pageable pageable) {
        String safeQuery = (query == null || query.isBlank()) ? null : query.trim();
        String safeRole = (role == null || role.isBlank()) ? null : role.trim();
        Page<User> page = user_repository.searchUsers(safeQuery, safeRole, pageable);
        return page.map(UserResponse::createUserResponse);
    }

    @Transactional(readOnly = true)
    public UserResponse get(Long id) {
        return UserResponse.createUserResponse(requireFeature(id));
    }

    @Transactional
    public UserResponse update(Long id, UpdateUserRequest update) {
        User feature = requireFeature(id);
        String username = update.username().trim();
        String email = update.email().toLowerCase().trim();
        boolean is_active = update.isActive();
        if (user_repository.existsByUserNameIgnoreCaseAndIdNot(username, id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "NAME_ALREADY_EXISTS", "UserName already exists");
        }

        if (user_repository.existsByEmailIgnoreCaseAndIdNot(email,id)) {
            throw new BusinessException(HttpStatus.CONFLICT, "EMAIL_ALREADY_EXISTS", "Email already exists");
        }

        Set<Role> roles = new HashSet<>();

        for (RoleEnum role : update.roles()) {
            Role dbRole = role_repository.findByRoleCode(role.name())
                    .orElseThrow(() -> new BusinessException(
                            HttpStatus.BAD_REQUEST,
                            "ROLE_NOT_FOUND",
                            "Lỗi: Không tìm thấy Role " + role.name() + " trong hệ thống!"
                    ));

            roles.add(dbRole);
        }

        feature.setEmail(email);
        feature.setActive(is_active);
        
        if (update.password() != null && !update.password().trim().isEmpty()) {
            feature.setPasswordHash(passwordEncoder.encode(update.password()));
        }
        
        feature.setRoles(roles);

        return UserResponse.createUserResponse(user_repository.save(feature));
    }


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

    public void deleteUser(Long id) {
        User user = requireFeature(id);
        user_repository.delete(user);
    }



    String normalizeEmail(String email) {
        if (email == null || email.isBlank()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "EMAIL_REQUIRED", "Email là bắt buộc");
        }
        return email.trim().toLowerCase(Locale.ROOT);
    }

    String normalizeUserName(String userName) {
        if (userName == null || userName.isBlank()) {
            throw new BusinessException(HttpStatus.BAD_REQUEST, "USERNAME_REQUIRED", "Tên đăng nhập là bắt buộc");
        }
        return userName.trim().toLowerCase();
    }

    CurrentUser toCurrentUser(User user) {
        List<String> roles = user.getRoles().stream().map(Role::getRoleCode).sorted().toList();
        return new CurrentUser(user.getId(), user.getEmail(), user.getUserName(), roles);
    }

    BusinessException invalidCredentials() {
        return new BusinessException(HttpStatus.UNAUTHORIZED, "INVALID_CREDENTIALS",
                "Email hoặc mật khẩu không đúng");
    }
    BusinessException informationAlreadyExists() {
        return new BusinessException(
                HttpStatus.CONFLICT,
                "INFORMATION_ALREADY_EXISTS",
                "Email hoặc Username đã tồn tại"
        );
    }

    private User requireFeature(Long id) {
        return user_repository.findById(id).orElseThrow(() -> new BusinessException(
                HttpStatus.NOT_FOUND, "ID_NOT_FOUND", "User not found"
        ));
    }

}
