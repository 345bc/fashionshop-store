package com.huit.zella.order;

import com.huit.zella.product.Product;
import com.huit.zella.productvariant.ProductVariant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.math.BigDecimal;

@Entity
@Table(name = "order_items")
@Getter
@Setter
public class OrderItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private Order order;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_id") private ProductVariant variant;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "product_id") private Product product;
    @Nationalized @Column(name = "product_name", length = 200) private String productName;
    @Column(length = 100) private String sku;
    @Column(name = "unit_price", precision = 18, scale = 2) private BigDecimal unitPrice;
    @Column(name = "unit_cost", precision = 18, scale = 2) private BigDecimal unitCost = BigDecimal.ZERO;
    private Integer quantity;
}

