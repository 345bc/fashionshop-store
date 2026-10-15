package com.huit.zella.staff;

import java.time.LocalDate;
import java.util.List;

import com.huit.zella.auth.Role;

public record StaffResponse(
        Long id, Long userId, String fullName, String position, String phone,
        LocalDate hiredDate, String username, String email,
        boolean accountActive, List<String> roles) {
    static StaffResponse from(Staff s) {
        var u = s.getUser();
        return new StaffResponse(s.getId(), u.getId(), s.getFullName(), s.getPosition(), s.getPhone(), s.getHiredDate(), u.getUserName(), u.getEmail(), u.isActive(), u.getRoles().stream().map(Role::getRoleCode).sorted().toList());
    }
}
