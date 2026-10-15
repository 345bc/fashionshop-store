package com.huit.zella.role;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/v1/role") @RequiredArgsConstructor @PreAuthorize("hasRole('ADMIN')")
public class RoleCreateController {
 private final RoleCreateService service;
 @PostMapping public ApiResponse<RoleCreateService.Response> create(@Valid @RequestBody RoleCreateRequest request) {
  return ApiResponse.success(service.create(request),"Đã thêm role");
 }
}
