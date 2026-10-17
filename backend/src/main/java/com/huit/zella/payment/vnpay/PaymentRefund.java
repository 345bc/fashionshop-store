package com.huit.zella.payment.vnpay;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity @Table(name = "payment_refunds") @Getter @Setter
public class PaymentRefund {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(name = "order_id", nullable = false) private Long orderId;
    @Column(name = "return_id") private Long returnId;
    @Column(name = "request_id", length = 32, nullable = false) private String requestId;
    @Column(length = 60, nullable = false) private String target;
    @Column(precision = 18, scale = 2, nullable = false) private BigDecimal amount;
    @Column(length = 20, nullable = false) private String state;
    @Column(name = "merchant_code", length = 8, nullable = false) private String merchantCode;
    @Column(name = "transaction_type", length = 2, nullable = false) private String transactionType;
    @Column(name = "transaction_date", length = 14, nullable = false) private String transactionDate;
    @Column(name = "transaction_no", length = 20, nullable = false) private String transactionNo;
    @Column(name = "refund_transaction_no", length = 20) private String refundTransactionNo;
    @Column(name = "response_code", length = 10) private String responseCode;
    @Column(name = "gateway_status", length = 10) private String gatewayStatus;
    @Nationalized @Column(length = 400, nullable = false) private String note;
    @Column(name = "actor_id", nullable = false) private Long actorId;
    @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
    @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;
}
