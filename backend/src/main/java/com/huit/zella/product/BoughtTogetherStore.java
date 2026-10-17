package com.huit.zella.product;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.time.*;
import java.util.*;

@Repository @RequiredArgsConstructor
public class BoughtTogetherStore {
    private final JdbcTemplate jdbc;
    public Map<Long,String> productNames(Collection<Long> productIds) {
        List<Long> ids=productIds.stream().distinct().sorted().toList();
        Map<Long,String> names=new HashMap<>();
        for(int offset=0;offset<ids.size();offset+=500) {
            var batch=ids.subList(offset,Math.min(offset+500,ids.size()));
            String placeholders=String.join(",",Collections.nCopies(batch.size(),"?"));
            jdbc.query("select id,name from products where id in ("+placeholders+")",
                (org.springframework.jdbc.core.RowCallbackHandler) rs->names.put(rs.getLong("id"),rs.getString("name")),batch.toArray());
        }
        return names;
    }
    public List<Set<Long>> load(Instant from,Instant to) {
        Map<Long,Set<Long>> baskets=new LinkedHashMap<>();
        jdbc.query("""
            WITH deliveries AS (
                SELECT order_id,MIN(created_at) delivered_at FROM order_histories
                WHERE new_status='DELIVERED' GROUP BY order_id
            ), returned AS (
                SELECT ri.order_item_id,SUM(CAST(ri.quantity AS BIGINT)) quantity
                FROM return_items ri JOIN return_requests rr ON rr.id=ri.return_request_id
                WHERE rr.status IN ('RECEIVED','COMPLETED') AND rr.received_at<=?
                GROUP BY ri.order_item_id
            )
            SELECT o.id order_id,oi.product_id,
                SUM(CASE WHEN oi.quantity>COALESCE(r.quantity,0)
                    THEN CAST(oi.quantity AS BIGINT)-COALESCE(r.quantity,0) ELSE 0 END) quantity
            FROM orders o JOIN deliveries d ON d.order_id=o.id
            LEFT JOIN order_items oi ON oi.order_id=o.id
            LEFT JOIN returned r ON r.order_item_id=oi.id
            WHERE o.order_status IN ('DELIVERED','RETURNED') AND d.delivered_at>=? AND d.delivered_at<=?
            GROUP BY o.id,oi.product_id
            """,(org.springframework.jdbc.core.RowCallbackHandler) rs->{
                var basket=baskets.computeIfAbsent(rs.getLong("order_id"),k->new HashSet<>());
                if(rs.getObject("product_id")!=null && rs.getLong("quantity")>0) basket.add(rs.getLong("product_id"));
            },LocalDateTime.ofInstant(to,ZoneOffset.UTC),LocalDateTime.ofInstant(from,ZoneOffset.UTC),LocalDateTime.ofInstant(to,ZoneOffset.UTC));
        return List.copyOf(baskets.values());
    }
}
