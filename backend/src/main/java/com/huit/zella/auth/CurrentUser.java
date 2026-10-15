package com.huit.zella.auth;

import java.io.Serializable;
import java.util.List;


//Serializable → đánh dấu object có thể serialize
// (chuyển thành dữ liệu) để lưu trữ hoặc truyền đi.
public record CurrentUser(Long id, String email, String username, List<String> roles, String activeRole) implements Serializable {
    public CurrentUser(Long id, String email, String username, List<String> roles) {
        this(id, email, username, roles, roles.isEmpty() ? null : roles.getFirst());
    }

    public CurrentUser withActiveRole(String role) {
        if (role == null || !roles.contains(role)) {
            throw new com.huit.zella.common.exception.BusinessException(
                    org.springframework.http.HttpStatus.FORBIDDEN, "ROLE_NOT_ASSIGNED", "Vai trò không còn được cấp cho tài khoản");
        }
        return new CurrentUser(id, email, username, roles, role);
    }

    @com.fasterxml.jackson.annotation.JsonProperty("roleSelectionRequired")
    public boolean roleSelectionRequired() { return activeRole == null; }

    public CurrentUser pendingRoleSelection() { return new CurrentUser(id, email, username, roles, null); }

    public boolean hasRole(String role) {
        return role.equals(activeRole);
    }
}
