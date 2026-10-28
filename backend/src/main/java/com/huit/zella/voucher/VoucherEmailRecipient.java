package com.huit.zella.voucher;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.Instant;

@Entity @Table(name = "voucher_email_recipients") @Getter @Setter
public class VoucherEmailRecipient {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(name = "voucher_id", nullable = false) private Long voucherId;
    @Column(nullable = false, length = 254) private String email;
    @Column(name = "membership_tier", nullable = false, length = 20) private String membershipTier;
    @JdbcTypeCode(SqlTypes.TIMESTAMP) @Column(name = "queued_at", nullable = false) private Instant queuedAt;
}
