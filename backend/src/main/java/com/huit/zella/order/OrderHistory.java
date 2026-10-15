package com.huit.zella.order;

import com.huit.zella.auth.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Entity
@Table(name = "order_histories")
@Getter
@Setter
public class OrderHistory {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private Order order;
    @Column(name = "old_status", length = 30) private String oldStatus;
    @Column(name = "new_status", length = 30) private String newStatus;
    @Nationalized @Column(length = 500) private String note;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "created_by") private User createdBy;
    @Column(name = "created_at") private LocalDateTime createdAt = LocalDateTime.now(ZoneOffset.UTC);
}
