package com.huit.zella.orderreturn;

import com.huit.zella.auth.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Entity @Table(name = "return_request_histories") @Getter @Setter
public class ReturnHistory {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "return_request_id") private ReturnRequest request;
    @Column(name = "old_status", length = 30) private String oldStatus;
    @Column(name = "new_status", length = 30) private String newStatus;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "changed_by") private User changedBy;
    @Nationalized @Column(length = 500) private String note;
    @Column(name = "created_at") private LocalDateTime createdAt = LocalDateTime.now(ZoneOffset.UTC);
}
