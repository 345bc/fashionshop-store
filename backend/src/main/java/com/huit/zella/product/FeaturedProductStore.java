package com.huit.zella.product;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.time.*;
import java.util.List;

@Repository @RequiredArgsConstructor
public class FeaturedProductStore {
    private final JdbcTemplate jdbc;
    public record Observation(Long productId,long transactions,long netQuantity,long reviewCount,double rating) {}
    public record Data(long totalTransactions,double baselineRating,List<Observation> products) {}
    private record Row(long total,double baseline,Observation observation) {}

    public Data load(Instant from,Instant to) {
        var rows=jdbc.query("""
            WITH deliveries AS (
                SELECT order_id,MIN(created_at) delivered_at FROM order_histories
                WHERE new_status='DELIVERED' GROUP BY order_id
            ), eligible_orders AS (
                SELECT o.id FROM orders o JOIN deliveries d ON d.order_id=o.id
                WHERE d.delivered_at>=? AND d.delivered_at<=?
                  AND o.order_status IN ('DELIVERED','RETURNED')
            ), returned AS (
                SELECT ri.order_item_id,SUM(CAST(ri.quantity AS BIGINT)) quantity
                FROM return_items ri JOIN return_requests rr ON rr.id=ri.return_request_id
                WHERE rr.status IN ('RECEIVED','COMPLETED') AND rr.received_at<=?
                GROUP BY ri.order_item_id
            ), baskets AS (
                SELECT oi.order_id,oi.product_id,
                    SUM(CASE WHEN oi.quantity>COALESCE(r.quantity,0)
                        THEN CAST(oi.quantity AS BIGINT)-COALESCE(r.quantity,0) ELSE 0 END) quantity
                FROM order_items oi JOIN eligible_orders o ON o.id=oi.order_id
                LEFT JOIN returned r ON r.order_item_id=oi.id
                GROUP BY oi.order_id,oi.product_id
            ), sales AS (
                SELECT product_id,COUNT_BIG(*) transactions,SUM(quantity) net_quantity
                FROM baskets WHERE quantity>0 GROUP BY product_id
            ), ratings AS (
                SELECT product_id,COUNT_BIG(*) reviews,AVG(CAST(rating AS FLOAT)) rating
                FROM product_reviews WHERE is_hidden=0 AND rating BETWEEN 1 AND 5 AND created_at<=?
                GROUP BY product_id
            ), baseline AS (
                SELECT COALESCE(AVG(CAST(rating AS FLOAT)),3.0) rating FROM product_reviews
                WHERE is_hidden=0 AND rating BETWEEN 1 AND 5 AND created_at<=?
            ), totals AS (SELECT COUNT_BIG(*) total FROM eligible_orders)
            SELECT t.total,b.rating baseline,s.product_id,s.transactions,s.net_quantity,
                COALESCE(r.reviews,0) reviews,COALESCE(r.rating,b.rating) rating
            FROM totals t CROSS JOIN baseline b LEFT JOIN sales s ON EXISTS (
                SELECT 1 FROM products p JOIN categories c ON c.id=p.category_id
                WHERE p.id=s.product_id AND p.is_active=1 AND c.is_active=1
                  AND EXISTS (SELECT 1 FROM product_variants v WHERE v.product_id=p.id AND v.is_active=1 AND v.stock_quantity>v.reserved_quantity)
            )
            LEFT JOIN ratings r ON r.product_id=s.product_id
            """,(rs,row)->new Row(rs.getLong("total"),rs.getDouble("baseline"),
                rs.getObject("product_id")==null?null:new Observation(rs.getLong("product_id"),rs.getLong("transactions"),
                    rs.getLong("net_quantity"),rs.getLong("reviews"),rs.getDouble("rating"))),
            LocalDateTime.ofInstant(from,ZoneOffset.UTC),LocalDateTime.ofInstant(to,ZoneOffset.UTC),
            LocalDateTime.ofInstant(to,ZoneOffset.UTC),LocalDateTime.ofInstant(to,ZoneOffset.UTC),LocalDateTime.ofInstant(to,ZoneOffset.UTC));
        if(rows.isEmpty()) return new Data(0,3,List.of());
        return new Data(rows.getFirst().total(),rows.getFirst().baseline(),rows.stream().map(Row::observation).filter(java.util.Objects::nonNull).toList());
    }
}
