package com.huit.zella.promotion;

import com.huit.zella.product.Product;
import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.*;

import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

@Entity
@Table(name = "promotion")
@Getter
@Setter
public class Promotion {
    @Column(name="image_url",length=500) private String imageUrl;
    @Column(name="is_display",nullable=false) private boolean display;
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Nationalized
    @Column(length = 200, nullable = false)
    private String name;
    @Nationalized
    @Column(length = 500)
    private String description;
    @Column(name = "discount_percent", precision = 5, scale = 2, nullable = false)
    private BigDecimal discountPercent;
    @Column(name = "startdate", nullable = false)
    private Instant startsAt;
    @Column(name = "enddate", nullable = false)
    private Instant endsAt;
    @Column(name = "is_active", nullable = false)
    private boolean active;
    @Column(name = "target_mode", length = 20, nullable = false)
    private String targetMode = "SELECTED";
    @Column(name = "created_at", nullable = false)
    private Instant createdAt;
    @Column(name = "updated_at")
    private Instant updatedAt;
    @ManyToMany
    @JoinTable(name = "promotionproduct", joinColumns = @JoinColumn(name = "promotion_id"), inverseJoinColumns = @JoinColumn(name = "product_id"))
    private Set<Product> products = new LinkedHashSet<>();
}
