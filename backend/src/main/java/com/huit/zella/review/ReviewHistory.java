package com.huit.zella.review;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.time.Instant;

@Entity @Table(name = "review_history") @Getter @Setter
public class ReviewHistory {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "review_id", nullable = false) private ProductReview review;
    @Nationalized @Column(nullable = false, length = 100) private String action;
    @Nationalized @Column(nullable = false, length = 255) private String actor;
    @Nationalized @Column(nullable = false, length = 1000) private String note;
    @Column(name = "created_at", nullable = false) private Instant createdAt = Instant.now();
}
