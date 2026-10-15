package com.huit.zella.productvariant;

import com.huit.zella.color.Color;
import com.huit.zella.product.Product;
import com.huit.zella.size.Size;
import com.huit.zella.supplier.Supplier;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.math.BigDecimal;

@Entity
@Table(name = "product_variants")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ProductVariant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "product_id",
            nullable = false,
            foreignKey = @ForeignKey(name = "fk_variant_product")
    )
    private Product product;

    @Column(length = 100, unique = true, nullable = false)
    private String sku;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "size_id",
            nullable = false,
            foreignKey = @ForeignKey(name = "fk_var_size")
    )
    private Size size;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(
            name = "color_id",
            nullable = false,
            foreignKey = @ForeignKey(name = "fk_var_color")
    )
    private Color color;

    @Column(precision = 18, scale = 2, nullable = false)
    private BigDecimal price;

    @Column(name = "cost_price", precision = 18, scale = 2, nullable = false)
    private BigDecimal costPrice = BigDecimal.ZERO;

    @Column(name ="stock_quantity" , nullable = false)
    private Integer stockQuantity =0;

    @Column(name ="reserved_quantity",nullable = false )
    private Integer reservedQuantity =0;

    @Column(name = "is_active", nullable = false)
    private boolean isActive = true;
}
