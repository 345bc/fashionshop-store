package com.huit.zella.goodsreceipt;
import com.huit.zella.auth.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity @Table(name = "supplier_returns") @Getter @Setter
public class SupplierReturn {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(length = 50) private String code;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "receipt_id") private GoodsReceipt receipt;
    @Nationalized @Column(length = 500) private String reason;
    @Column(precision = 18, scale = 2) private BigDecimal amount;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "created_by") private User createdBy;
    @Column(name = "created_at") private Instant createdAt = Instant.now();
    @OneToMany(mappedBy = "document", cascade = CascadeType.ALL) @OrderBy("id ASC")
    private List<SupplierReturnItem> items = new ArrayList<>();
}

