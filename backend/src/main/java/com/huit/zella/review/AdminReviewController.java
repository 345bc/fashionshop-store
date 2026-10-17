package com.huit.zella.review;

import com.huit.zella.common.api.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;

@RestController @RequestMapping("/api/v1/admin/reviews")
@RequiredArgsConstructor @Validated
@PreAuthorize("hasAnyRole('ADMIN', 'CUSTOMER_SUPPORT')")
public class AdminReviewController {
    private final AdminReviewService service;

    @GetMapping
    public ApiResponse<PageResponse<AdminReviewResponse>> list(
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "100") @Min(1) @Max(100) int size) {
        return ApiResponse.success(PageResponse.from(service.list(PageRequest.of(page, size,
                Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"))))));
    }

    @GetMapping("/{id}")
    public ApiResponse<AdminReviewResponse> get(@PathVariable @Positive long id) {
        return ApiResponse.success(service.get(id));
    }

    @PutMapping("/{id}/reply")
    public ApiResponse<AdminReviewResponse> reply(@PathVariable @Positive long id,
            @Valid @RequestBody ReviewReplyRequest request, Principal principal) {
        return ApiResponse.success(service.reply(id, request, principal.getName()));
    }

    @PutMapping("/{id}/visibility")
    public ApiResponse<AdminReviewResponse> moderate(@PathVariable @Positive long id,
            @Valid @RequestBody ReviewModerationRequest request, Principal principal) {
        return ApiResponse.success(service.moderate(id, request, principal.getName()));
    }
}
