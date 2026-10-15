package com.huit.zella.role;
import jakarta.validation.constraints.*;
public record RoleCreateRequest(
 @NotBlank @Size(max=50) @Pattern(regexp="[A-Za-z][A-Za-z0-9_]{0,49}",message="Mã role chỉ gồm chữ, số và dấu gạch dưới") String roleCode,
 @NotBlank @Size(max=100) String roleName,
 @Size(max=255) String description
) {}
