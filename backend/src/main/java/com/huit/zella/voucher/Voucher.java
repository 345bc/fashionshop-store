package com.huit.zella.voucher;
import com.huit.zella.customer.Customer;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
@Entity @Table(name="vouchers") @Getter @Setter
public class Voucher {
    @Column(name="source_reward_id") private Long sourceRewardId;
    @Nationalized @Column(length=200) private String name;
    @Id @GeneratedValue(strategy=GenerationType.IDENTITY) private Long id;
    @Column(unique=true,length=50) private String code;
    @Nationalized @Column(length=500) private String description;
    @Column(name="discount_type") private String discountType;
    @Column(name="discount_value",precision=18,scale=2) private BigDecimal discountValue;
    @Column(name="discount_amount",precision=18,scale=2) private BigDecimal discountAmount=BigDecimal.ZERO;
    @Column(name="min_order_amount",precision=18,scale=2) private BigDecimal minOrderAmount=BigDecimal.ZERO;
    @Column(name="usage_limit") private Integer usageLimit;
    @Column(name="used_count") private Integer usedCount=0;
    @Column(name="is_active") private boolean active=true;
    @Convert(converter=UtcDateTimeConverter.class) @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.TIMESTAMP)
    @Column(name="start_date") private LocalDateTime startDate;
    @Convert(converter=UtcDateTimeConverter.class) @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.TIMESTAMP)
    @Column(name="end_date") private LocalDateTime endDate;
    @Convert(converter=UtcDateTimeConverter.class) @org.hibernate.annotations.JdbcTypeCode(org.hibernate.type.SqlTypes.TIMESTAMP)
    @Column(name="created_at") private LocalDateTime createdAt;
    @Column(name="points_required") private Integer pointsRequired;
    @Column(name="is_redeemable") private boolean redeemable;
    @ManyToOne(fetch=FetchType.LAZY) @JoinColumn(name="owner_customer_id") private Customer owner;
    @Column(name="redemption_key",length=36) private String redemptionKey;
}
