package com.huit.zella.customer;


import java.math.BigDecimal;
import java.time.Instant;

public record CustomerResponse(
        Long id,
        Long userId,
        String email,
        String username,
        Boolean isActive,
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
                customerEntity.getUser() != null ? customerEntity.getUser().getUserName() : null,
                customerEntity.getUser() != null ? customerEntity.getUser().isActive() : null,
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
