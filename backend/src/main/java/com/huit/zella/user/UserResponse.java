package com.huit.zella.user;

import com.huit.zella.auth.Role;
import com.huit.zella.auth.User;
import com.huit.zella.enums.RoleEnum;
import java.time.Instant;
import java.util.Set;
import java.util.stream.Collectors;

public record UserResponse(
        Long id,
        String username,
        String email,
        Set<String> roles,
        boolean isActive,
        Instant createdAt,
        Instant updatedAt) {
    public static UserResponse createUserResponse(User user) {
        Set<String> roleNames = user.getRoles().stream()
                .map(Role::getRoleCode)
                .collect(Collectors.toSet());
        return new UserResponse(
                user.getId(), 
                user.getUserName(), 
                user.getEmail(), 
                roleNames, 
                user.isActive(), 
                user.getCreatedAt(), 
                user.getUpdatedAt()
        );
    }
}
