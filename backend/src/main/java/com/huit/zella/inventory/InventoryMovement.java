package com.huit.zella.inventory;
import com.huit.zella.auth.User;
import com.huit.zella.productvariant.ProductVariant;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;
import java.time.Instant;
@Entity @Table(name = "inventory_movements") @Getter @Setter
public class InventoryMovement {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "variant_id", nullable = false) private ProductVariant variant;
    @Column(name = "movement_type", nullable = false, length = 30) private String movementType;
    @Column(name = "quantity_change", nullable = false) private Integer quantityChange;
    @Column(name = "before_quantity", nullable = false) private Integer beforeQuantity;
    @Column(name = "after_quantity", nullable = false) private Integer afterQuantity;
    @Column(name = "before_reserved") private Integer beforeReserved;
    @Column(name = "after_reserved") private Integer afterReserved;
    @Column(name = "reference_code", nullable = false, length = 50) private String referenceCode;
    @Nationalized @Column(length = 500) private String reason;
    @Column(name = "created_at", nullable = false) private Instant createdAt = Instant.now();
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "created_by") private User createdBy;
}
