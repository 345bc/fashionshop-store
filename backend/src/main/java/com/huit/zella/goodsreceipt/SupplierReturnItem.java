package com.huit.zella.goodsreceipt;
import com.huit.zella.productvariant.ProductVariant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import java.math.BigDecimal;

@Entity @Table(name = "supplier_return_items") @Getter @Setter
public class SupplierReturnItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "supplier_return_id") private SupplierReturn document;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_id") private ProductVariant variant;
    private Integer quantity;
    @Column(name = "unit_cost", precision = 18, scale = 2) private BigDecimal unitCost;
}

