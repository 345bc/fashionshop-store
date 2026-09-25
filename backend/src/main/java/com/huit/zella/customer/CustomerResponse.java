package com.huit.zella.customer;

import com.huit.zella.auth.User;
import jakarta.persistence.*;
import org.hibernate.annotations.Nationalized;

import java.math.BigDecimal;
import java.time.Instant;

public record CustomerResponse(
        Long id,
        Long userId,
        String email,
        String fullName,
        String phone,
        String address,
        Instant createdAt,
        Instant updatedAt,
        String membershipTier,
        Integer rewardPoints,
        BigDecimal totalSpending,
        Instant tierUpgradedAt
) {
    public static CustomerResponse from(Customer customerEntity) {
        return new CustomerResponse(
                customerEntity.getId(),
                customerEntity.getUser() != null ? customerEntity.getUser().getId() : null,
                customerEntity.getUser() != null ? customerEntity.getUser().getEmail() : null,
                customerEntity.getFullName(),
                customerEntity.getPhone(),
                customerEntity.getAddress(),
                customerEntity.getCreatedAt(),
                customerEntity.getUpdatedAt(),
                customerEntity.getMembershipTier(),
                customerEntity.getRewardPoints(),
                customerEntity.getTotalSpending(),
                customerEntity.getTierUpgradedAt()
        );
    }
}
