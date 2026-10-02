package com.huit.zella.goodsreceipt;
import com.huit.zella.productvariant.ProductVariant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.math.BigDecimal;
@Entity @Table(name = "goods_receipt_items") @Getter @Setter
public class GoodsReceiptItem {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "receipt_id", nullable = false) private GoodsReceipt receipt;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_id", nullable = false) private ProductVariant variant;
    @Column(nullable = false) private Integer quantity;
    @Column(name = "unit_cost", nullable = false, precision = 18, scale = 2) private BigDecimal unitCost;
    @Column(name = "before_unit_cost", precision = 18, scale = 2) private BigDecimal beforeUnitCost;
    @Column(name = "sku_snapshot", length = 100) private String skuSnapshot;
    @Nationalized @Column(name = "product_name_snapshot", length = 200) private String productNameSnapshot;
    @Column(name = "size_name_snapshot", length = 20) private String sizeNameSnapshot;
    @Nationalized @Column(name = "color_name_snapshot", length = 50) private String colorNameSnapshot;
}
