package com.huit.zella.auth;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/auth") @RequiredArgsConstructor
public class PasswordResetController {
    private final PasswordResetService service;
    private final java.util.Map<String, Window> requests = new java.util.HashMap<>();
    private record Window(long start, int count) {}

    // Bound memory and limit requests from one connection address; never trust raw forwarded headers.
    private synchronized void limit(String address) {
        long now = System.currentTimeMillis();
        requests.entrySet().removeIf(entry -> now - entry.getValue().start() >= 900_000);
        Window window = requests.get(address);
        if ((window != null && window.count() >= 10) || (window == null && requests.size() >= 10_000))
            throw new com.huit.zella.common.exception.BusinessException(org.springframework.http.HttpStatus.TOO_MANY_REQUESTS,
                    "RESET_RATE_LIMIT", "Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau 15 phút.");
        requests.put(address, new Window(window == null ? now : window.start(), window == null ? 1 : window.count() + 1));
    }

    @PostMapping("/forgot-password")
    public ApiResponse<Void> forgot(@Valid @RequestBody ForgotRequest request, jakarta.servlet.http.HttpServletRequest servletRequest) {
        limit(servletRequest.getRemoteAddr());
        service.request(request.email());
        return ApiResponse.success(null, "Vui lòng kiểm tra email đã đăng ký.");
    }

    @PostMapping("/reset-password")
    public ApiResponse<Void> reset(@Valid @RequestBody ResetRequest request, jakarta.servlet.http.HttpServletRequest servletRequest) {
        limit(servletRequest.getRemoteAddr());
        service.reset(request.token(), request.password());
        return ApiResponse.success(null, "Đã đổi mật khẩu. Vui lòng đăng nhập lại.");
    }

    public record ForgotRequest(@NotBlank @Email @Size(max = 100) String email) {}
    public record ResetRequest(@NotBlank @Pattern(regexp = "[A-Za-z0-9_-]{43}") String token,
            @NotBlank @Size(min = 8, max = 72) String password) {}
}
