package com.huit.zella.loyalty;
import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.api.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/me/loyalty") @RequiredArgsConstructor
public class LoyaltyController {
    private final LoyaltyService service;
    public record RedeemRequest(@NotNull @Positive Long rewardId,@NotBlank @Pattern(regexp="[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89aAbB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}") String key) {}
    @GetMapping public ApiResponse<LoyaltyService.Summary> summary(@AuthenticationPrincipal CurrentUser user) { return ApiResponse.success(service.summary(user.id())); }
    @GetMapping("/vouchers") public ApiResponse<PageResponse<LoyaltyService.Offer>> vouchers(@AuthenticationPrincipal CurrentUser user,
            @RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="10") int size) {
        return ApiResponse.success(PageResponse.from(service.wallet(user.id(),PageRequest.of(Math.max(0,page),Math.clamp(size,1,50),Sort.by(Sort.Direction.DESC,"id")))));
    }
    @GetMapping("/history") public ApiResponse<PageResponse<LoyaltyService.Entry>> history(@AuthenticationPrincipal CurrentUser user,
            @RequestParam(required=false) LocalDate from,@RequestParam(required=false) LocalDate to,@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="10") int size) {
        return ApiResponse.success(PageResponse.from(service.history(user.id(),from,to,PageRequest.of(Math.max(0,page),Math.clamp(size,1,50),Sort.by(Sort.Direction.DESC,"id")))));
    }
    @PostMapping("/redeem") public ApiResponse<LoyaltyService.Offer> redeem(@AuthenticationPrincipal CurrentUser user,@Valid @RequestBody RedeemRequest request) { return ApiResponse.success(service.redeem(user.id(),request.rewardId(),request.key())); }
}
