package com.huit.zella.customer;

import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageRequest;

import com.huit.zella.common.api.PageResponse;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.auth.CurrentUser;
import com.huit.zella.common.exception.BusinessException;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/customers")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CustomerController {

    CustomerService customerService;

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @GetMapping
    public ApiResponse<PageResponse<CustomerResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) String tier,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(customerService.list(
                q, tier,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @GetMapping("/{id}")
    public ApiResponse<CustomerResponse> get(@PathVariable Long id) {
        return ApiResponse.success(customerService.getById(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<CustomerResponse> update(@PathVariable Long id, @Valid @RequestBody UpdateCustomerRequest request) {
        return ApiResponse.success(customerService.update(id, request));
    }

    @GetMapping("/user/{id}")
    public ApiResponse<CustomerResponse> getCustomerByUserId(@PathVariable Long id, Authentication authentication) {
        if (!(authentication.getPrincipal() instanceof CurrentUser current)
                || (!current.id().equals(id) && !current.hasRole("ADMIN") && !current.hasRole("EMPLOYEE"))) {
            throw new BusinessException(HttpStatus.FORBIDDEN, "CUSTOMER_ACCESS_DENIED", "Cannot view this customer");
        }
        return ApiResponse.success(customerService.get(id));
    }

}
