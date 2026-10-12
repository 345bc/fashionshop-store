package com.huit.zella.auth;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.Instant;

@Entity @Table(name = "refresh_sessions") @Getter @Setter
public class RefreshSession {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false) private User user;
    @Column(name = "token_hash", nullable = false, length = 64) private String tokenHash;
    @Column(name = "previous_token_hash", length = 64) private String previousTokenHash;
    @Column(name = "password_fingerprint", nullable = false, length = 64) private String passwordFingerprint;
    @JdbcTypeCode(SqlTypes.TIMESTAMP) @Column(name = "created_at", nullable = false) private Instant createdAt;
    @JdbcTypeCode(SqlTypes.TIMESTAMP) @Column(name = "rotated_at", nullable = false) private Instant rotatedAt;
    @JdbcTypeCode(SqlTypes.TIMESTAMP) @Column(name = "expires_at", nullable = false) private Instant expiresAt;
    @JdbcTypeCode(SqlTypes.TIMESTAMP) @Column(name = "revoked_at") private Instant revokedAt;
}
