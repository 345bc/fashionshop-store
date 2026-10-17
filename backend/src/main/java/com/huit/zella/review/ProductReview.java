package com.huit.zella.review;

import com.huit.zella.customer.Customer;
import com.huit.zella.order.Order;
import com.huit.zella.order.OrderItem;
import com.huit.zella.product.Product;
import jakarta.persistence.*;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.Nationalized;

@Entity @Table(name = "product_reviews") @Getter @Setter
public class ProductReview {
    @Nationalized @Column(name = "moderation_reason", length = 500) private String moderationReason;
    @OneToMany(mappedBy = "review", cascade = CascadeType.ALL) @OrderBy("id ASC")
    private java.util.List<ReviewHistory> history = new java.util.ArrayList<>();
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "product_id") private Product product;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "customer_id") private Customer customer;
    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_id") private Order order;
    @OneToOne(fetch = FetchType.LAZY) @JoinColumn(name = "order_item_id", unique = true) private OrderItem orderItem;
    @Column(columnDefinition = "tinyint") private Integer rating;
    @Nationalized @Column(length = 1000) private String comment;
    @Nationalized @Column(name = "admin_reply", length = 1000) private String adminReply;
    @Column(name = "replied_at") private Instant repliedAt;
    @Column(name = "is_hidden") private boolean hidden;
    @Column(name = "created_at") private Instant createdAt = Instant.now();
    @Column(name = "updated_at") private Instant updatedAt;
}
