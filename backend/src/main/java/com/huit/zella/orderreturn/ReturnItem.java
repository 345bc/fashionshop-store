package com.huit.zella.orderreturn;

import com.huit.zella.order.OrderItem;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

@Entity @Table(name = "return_items") @Getter @Setter
public class ReturnItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "return_request_id") private ReturnRequest request;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_item_id") private OrderItem orderItem;
    private Integer quantity;
    @Column(name = "item_condition", length = 50) private String itemCondition;
    @Column(name = "unit_cost", precision = 18, scale = 2) private BigDecimal unitCost;
    @Column(name = "created_at") private LocalDateTime createdAt = LocalDateTime.now(ZoneOffset.UTC);
}
