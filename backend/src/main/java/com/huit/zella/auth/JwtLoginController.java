package com.huit.zella.auth;

import com.huit.zella.common.api.ApiResponse;
import jakarta.servlet.http.HttpServletResponse;
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
    private final JwtAccessTokenService tokenService;

    JwtLoginController(
            UserService appUserService,
            PasswordEncoder passwordEncoder,
            JwtAccessTokenService tokenService
    ) {
        this.appUserService = appUserService;
        this.passwordEncoder = passwordEncoder;
        this.tokenService = tokenService;
    }

    @PostMapping("/login")
    ApiResponse<CurrentUser> login(@Valid @RequestBody LoginRequest request, HttpServletResponse response) {
        CurrentUser user = appUserService.authenticate(request.email(), request.password(), passwordEncoder);
        tokenService.writeLoginCookie(response, user);
        return ApiResponse.success(user, "Đăng nhập thành công");
    }

    record LoginRequest(
            @NotBlank(message = "Email là bắt buộc") @Email(message = "Email không hợp lệ") String email,
            @NotBlank(message = "Mật khẩu là bắt buộc") String password
    ) {
    }

    record RegisterRequest(
            @NotBlank(message = "Email là bắt buộc") @Email(message = "Email không hợp lệ") String email,
            @NotBlank(message = "Mật khẩu là bắt buộc") String password
    ) {

//        @PostMapping("/register")
//        ApiResponse<CurrentUser> register(@Valid @RequestBody RegisterRequest request, HttpServletResponse response) {
//            CurrentUser user = appUserService.authenticate(request.email(), request.password(), passwordEncoder);
//            tokenService.writeLoginCookie(response, user);
//            return ApiResponse.success(user, "Đăng nhập thành công");
//        }
    }
}
