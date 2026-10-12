package com.huit.zella.auth;

import com.huit.zella.common.api.ApiResponse;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.huit.zella.common.api.ApiResponse;

@RestController
@RequestMapping("/api/v1/auth")
@Profile("jwt-auth")
public class JwtLoginController {
    private final UserService appUserService;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokens;

    JwtLoginController(
            UserService appUserService,
            PasswordEncoder passwordEncoder,
            RefreshTokenService refreshTokens
    ) {
        this.appUserService = appUserService;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokens = refreshTokens;
    }

    @PostMapping("/login")
    ApiResponse<CurrentUser> login(@Valid @RequestBody LoginRequest request, HttpServletRequest servletRequest, HttpServletResponse response) {
        CurrentUser user = appUserService.authenticate(request.email(), request.password(), passwordEncoder);
        refreshTokens.issue(user, servletRequest, response);
        return ApiResponse.success(user, "Đăng nhập thành công");
    }

    @PostMapping("/refresh")
    ApiResponse<CurrentUser> refresh(HttpServletRequest request, HttpServletResponse response) {
        return ApiResponse.success(refreshTokens.refresh(request, response));
    }

    @PostMapping("/register")
    ApiResponse<CurrentUser> register(@Valid @RequestBody RegisterRequest request, HttpServletResponse response) {
        CurrentUser user = appUserService.register(request.email(), request.username(), request.password(), request.fullName(), request.phone(), passwordEncoder);
        return ApiResponse.success(user, "Đăng ký thành công");
    }

    record LoginRequest(
            @NotBlank(message = "Email là bắt buộc") @Email(message = "Email không hợp lệ") String email,
            @NotBlank(message = "Mật khẩu là bắt buộc") String password
    ) {
    }

    record RegisterRequest(
            @NotBlank(message = "Email là bắt buộc") @Email(message = "Email không hợp lệ") String email,
            @NotBlank(message = "Mật khẩu là bắt buộc") String password,
            @NotBlank(message = "Tên là bắt buộc") String username,
            @NotBlank(message = "Họ và tên là bắt buộc") String fullName,
            String phone
    ) {

    }
}
