package com.huit.zella.goodsreceipt;

import com.huit.zella.auth.User;
import com.huit.zella.supplier.Supplier;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "goods_receipts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class GoodsReceipt {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "supplier_id", nullable = false)
    private Supplier supplier;

    @Column(name = "total_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal totalAmount = BigDecimal.ZERO;

    @Column(name = "returned_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal returnedAmount = BigDecimal.ZERO;

    @Column(name = "supplier_refunded_amount", nullable = false, precision = 18, scale = 2)
    private BigDecimal supplierRefundedAmount = BigDecimal.ZERO;

    @Column(name = "payment_status", length = 20)
    private String paymentStatus = "UNPAID";

    @Column(nullable = false, length = 20)
    private String status = "DRAFT";

    @Nationalized
    @Column(length = 500)
    private String note;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "posted_at")
    private Instant postedAt;

    @Column(name = "cancelled_at")
    private Instant cancelledAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "created_by")
    private User createdBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "posted_by")
    private User postedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "cancelled_by")
    private User cancelledBy;

    @OneToMany(mappedBy = "receipt", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("id ASC")
    private List<GoodsReceiptItem> items = new ArrayList<>();

    @OneToMany(mappedBy = "receipt", cascade = CascadeType.ALL)
    @OrderBy("id ASC")
    private List<SupplierPayment> payments = new ArrayList<>();

    @OneToMany(mappedBy = "receipt", cascade = CascadeType.ALL)
    @OrderBy("id ASC")
    private List<SupplierReturn> returns = new ArrayList<>();

    @OneToMany(mappedBy = "receipt", cascade = CascadeType.ALL)
    @OrderBy("id ASC")
    private List<SupplierRefund> refunds = new ArrayList<>();
}
