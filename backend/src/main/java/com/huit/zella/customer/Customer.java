package com.huit.zella.customer;

import com.huit.zella.auth.User;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

import java.math.BigDecimal;
import java.time.Instant;

@Entity
@Table(name = "customer_profiles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class Customer {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Nationalized
    @Column(name = "full_name", length = 100, nullable = false)
    private String fullName;

    @Column(length = 20)
    private String phone;

    @Nationalized
    @Column
    private String address;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Column(name = "membership_tier", length = 20)
    private String membershipTier = "STANDARD";

    @Column(name = "reward_points", nullable = false)
    private Integer rewardPoints = 0;

    @Column(name = "total_spending", precision = 18, scale = 2, nullable = false)
    BigDecimal totalSpending = BigDecimal.ZERO;

    @Column(name = "tier_upgraded_at")
    private Instant tierUpgradedAt;

    @PrePersist
    void prePersist() {
        createdAt = Instant.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = Instant.now();
    }
}
