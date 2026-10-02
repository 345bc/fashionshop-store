package com.huit.zella.order;

import com.huit.zella.auth.User;
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
@Table(name = "orders")
@Getter
@Setter
public class Order {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(name = "order_code", nullable = false, length = 32) private String code;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id") private User customer;
    @Nationalized @Column(name = "recipient_name", length = 150) private String recipientName;
    @Column(name = "recipient_phone", length = 20) private String recipientPhone;
    @Nationalized @Column(name = "recipient_note", length = 500) private String note;
    @Nationalized @Column(length = 350) private String address;
    @Column(precision = 18, scale = 2) private BigDecimal subtotal = BigDecimal.ZERO;
    @Column(name = "shipping_fee", precision = 18, scale = 2) private BigDecimal shippingFee = BigDecimal.ZERO;
    @Column(name = "discount_amount", precision = 18, scale = 2) private BigDecimal discountAmount = BigDecimal.ZERO;
    @Column(name = "total_amount", precision = 18, scale = 2) private BigDecimal totalAmount = BigDecimal.ZERO;
    @Column(name = "payment_method", length = 30) private String paymentMethod;
    @Column(name = "payment_status", length = 20) private String paymentStatus = "PENDING";
    @Enumerated(EnumType.STRING) @Column(name = "order_status", length = 30) private OrderStatus status = OrderStatus.PENDING;
    @Column(name = "points_earned", precision = 5, scale = 1) private BigDecimal pointsEarned = BigDecimal.ZERO;
    @Column(name = "inventory_managed", nullable = false) private boolean inventoryManaged = true;
    @Column(name = "created_at") private LocalDateTime createdAt = LocalDateTime.now(ZoneOffset.UTC);
    @Column(name = "updated_at") private LocalDateTime updatedAt = LocalDateTime.now(ZoneOffset.UTC);
    @Column(name = "payment_expires_at") private LocalDateTime paymentExpiresAt;
    @Column(name = "online_transaction_id", length = 100) private String onlineTransactionId;
    @Column(name = "checkout_token_hash", length = 64) private String checkoutTokenHash;
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL) @OrderBy("id ASC")
    private List<OrderItem> items = new ArrayList<>();
    @OneToMany(mappedBy = "order", cascade = CascadeType.ALL) @OrderBy("id ASC")
    private List<OrderHistory> histories = new ArrayList<>();
}
