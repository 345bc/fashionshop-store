package com.huit.zella.voucher;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.Set;

@RestController @RequestMapping("/api/v1/campaigns/voucher/{id}/email") @RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','MARKETING')")
public class VoucherEmailController {
    private final VoucherEmailService service;
    public record AudienceRequest(@NotEmpty @Size(max = 3) Set<@NotNull @Pattern(regexp = "STANDARD|SILVER|GOLD") String> tiers) {}
    public record SendRequest(@NotEmpty @Size(max = 3) Set<@NotNull @Pattern(regexp = "STANDARD|SILVER|GOLD") String> tiers,
                              @NotBlank @Pattern(regexp = "[a-f0-9]{64}") String audienceKey) {}

    @PostMapping("/preview")
    public ApiResponse<VoucherEmailService.Preview> preview(@PathVariable Long id, @Valid @RequestBody AudienceRequest request) {
        return ApiResponse.success(service.preview(id, request.tiers()));
    }

    @PostMapping("/send")
    public ApiResponse<VoucherEmailService.SendResult> send(@PathVariable Long id, @Valid @RequestBody SendRequest request) {
        return ApiResponse.success(service.send(id, request.tiers(), request.audienceKey()), "Đã đưa email voucher vào hàng đợi.");
    }
}
