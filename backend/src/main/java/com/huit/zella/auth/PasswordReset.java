package com.huit.zella.auth;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.time.Instant;

@Entity @Table(name = "password_resets") @Getter @Setter
public class PasswordReset {
    @Id @Column(name = "user_id") private Long userId;
    @Column(name = "token_hash", nullable = false, length = 64) private String tokenHash;
    @Column(name = "auth_version", nullable = false) private long authVersion;
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.TIMESTAMP)
    @Column(name = "created_at", nullable = false) private Instant createdAt;
    @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.TIMESTAMP)
    @Column(name = "expires_at", nullable = false) private Instant expiresAt;
}
