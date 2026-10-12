package com.huit.zella.orderreturn;

import com.huit.zella.auth.User;
import com.huit.zella.order.Order;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "return_requests")
@Getter
@Setter
public class ReturnRequest {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(name = "request_code", length = 32) private String code;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private Order order;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private User customer;
    @Column(name = "request_type", length = 20) private String requestType = "RETURN";
    @Column(name = "reason_code", length = 50) private String reasonCode = "CUSTOMER_RETURN";
    @Nationalized @Column(name = "customer_note", length = 500) private String note;
    @Nationalized @Column(name = "admin_note", length = 500) private String adminNote;
    @Enumerated(EnumType.STRING) @Column(length = 30) private ReturnStatus status = ReturnStatus.PENDING;
    @Column(name = "refund_amount", precision = 18, scale = 2) private BigDecimal refundAmount = BigDecimal.ZERO;
    @Column(name = "refund_method", length = 30) private String refundMethod;
    @Column(name = "approved_at") private LocalDateTime approvedAt;
    @Column(name = "rejected_at") private LocalDateTime rejectedAt;
    @Column(name = "received_at") private LocalDateTime receivedAt;
    @Column(name = "completed_at") private LocalDateTime completedAt;
    @Column(name = "cancelled_at") private LocalDateTime cancelledAt;
    @Column(name = "created_at") private LocalDateTime createdAt = LocalDateTime.now(ZoneOffset.UTC);
    @Column(name = "updated_at") private LocalDateTime updatedAt = LocalDateTime.now(ZoneOffset.UTC);
    @OneToMany(mappedBy = "request", cascade = CascadeType.ALL) @OrderBy("id ASC")
    private List<ReturnItem> items = new ArrayList<>();
    @OneToMany(mappedBy = "request", cascade = CascadeType.ALL) @OrderBy("id ASC")
    private List<ReturnHistory> histories = new ArrayList<>();
}
