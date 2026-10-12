package com.huit.zella.loyalty;

import com.huit.zella.customer.Customer;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

@Entity @Table(name="reward_transactions") @Getter @Setter
public class RewardTransaction {
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="customer_id") private Customer customer;
    private Integer points;
    @Column(name="balance_after") private Integer balanceAfter;
    @Nationalized @Column(length=300) private String description;
    @Column(name="reference_key", unique=true, length=100) private String referenceKey;
    @Column(name="created_at") private LocalDateTime createdAt;
}
