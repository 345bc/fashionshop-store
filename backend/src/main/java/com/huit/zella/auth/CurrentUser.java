package com.huit.zella.auth;

import java.io.Serializable;
import java.util.List;


//Serializable → đánh dấu object có thể serialize
// (chuyển thành dữ liệu) để lưu trữ hoặc truyền đi.
public record CurrentUser(Long id, String email, String username, List<String> roles) implements Serializable {
    public boolean hasRole(String role) {
        return roles.contains(role);
    }
}
