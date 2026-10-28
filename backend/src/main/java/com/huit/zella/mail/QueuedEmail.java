package com.huit.zella.mail;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.time.Instant;

@Entity @Table(name = "email_outbox") @Getter @Setter
public class QueuedEmail {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(nullable = false, length = 254) private String recipient;
    @Nationalized @Column(nullable = false, length = 255) private String subject;
    @Nationalized @Column(nullable = false, columnDefinition = "nvarchar(max)") private String body;
    @Nationalized @Column(name = "html_body", columnDefinition = "nvarchar(max)") private String htmlBody;
    @Column(nullable = false) private int attempts;
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.TIMESTAMP)
    @Column(name = "next_attempt_at", nullable = false) private Instant nextAttemptAt;
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.TIMESTAMP)
    @Column(name = "expires_at") private Instant expiresAt;
}
