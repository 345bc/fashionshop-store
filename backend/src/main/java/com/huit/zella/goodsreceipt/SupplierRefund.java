package com.huit.zella.goodsreceipt;
import com.huit.zella.auth.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.math.BigDecimal;
import java.time.Instant;

@Entity @Table(name = "supplier_refunds") @Getter @Setter
public class SupplierRefund {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "receipt_id") private GoodsReceipt receipt;
    @Column(precision = 18, scale = 2) private BigDecimal amount;
    @Column(name = "payment_method", length = 30) private String paymentMethod;
    @Nationalized @Column(length = 500) private String note;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "created_by") private User createdBy;
    @Column(name = "created_at") private Instant createdAt = Instant.now();
}

