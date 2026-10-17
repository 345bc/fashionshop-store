package com.huit.zella.dashboard;

import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.namedparam.*;
import org.springframework.stereotype.Repository;
import java.time.*;
import java.util.*;

/** Read-only aggregates over transaction snapshots; no reporting entities or seed data. */
@Repository @RequiredArgsConstructor
public class DashboardRepository {
    private final NamedParameterJdbcTemplate jdbc;
    // Legacy LocalDateTime attributes use Hibernate's TIMESTAMP/UTC Calendar binding,
    // which shifts their physical DATETIME2 values by the JVM offset. Normalize back
    // to the entity's UTC values before reporting. Instant/DATETIMEOFFSET fields do not need this.
    // MIN deduplicates repeated callbacks/status entries.
    static final String FACTS = """
        WITH history AS (
          SELECT order_id,
            DATEADD(minute,:jdbcOffset,MIN(CASE WHEN new_status='DELIVERED' THEN created_at END)) delivered_at,
            DATEADD(minute,:jdbcOffset,MIN(CASE WHEN (new_status='CONFIRMED' AND old_status='PENDING')
              OR note LIKE N'Thanh toán về sau khi đơn bị hủy, cần hoàn tiền.%' THEN created_at END)) paid_at,
            DATEADD(minute,:jdbcOffset,MIN(CASE WHEN new_status='CANCELLED' AND old_status='CANCELLED'
              AND note LIKE N'Đã hoàn %' THEN created_at END)) refunded_at
          FROM order_histories GROUP BY order_id
        ), item_totals AS (
          SELECT order_id, SUM(CAST(quantity AS BIGINT)) quantity,
            SUM(CASE WHEN original_unit_price>=unit_price THEN original_unit_price ELSE unit_price END * quantity) gross,
            SUM(unit_price * quantity) sold, SUM(unit_cost * quantity) cost
          FROM order_items GROUP BY order_id
        ), facts AS (
          SELECT o.id,o.order_code,o.recipient_name,o.recipient_phone,o.user_id,o.payment_status,o.order_status,
            o.subtotal,o.discount_amount,o.membership_discount_amount,o.voucher_id,o.total_amount,o.shipping_fee,
            DATEADD(minute,:jdbcOffset,o.created_at) created_at,h.delivered_at,h.paid_at,h.refunded_at,
            COALESCE(t.quantity,0) quantity, COALESCE(t.gross,o.subtotal) gross,
            COALESCE(t.gross-t.sold,0) promotion_discount, COALESCE(t.cost,0) cost,
            o.subtotal-o.discount_amount goods,
            CASE WHEN o.user_id IS NOT NULL THEN CONCAT('user:',o.user_id)
                 WHEN NULLIF(LTRIM(RTRIM(o.recipient_phone)),'') IS NOT NULL THEN CONCAT('phone:',LTRIM(RTRIM(o.recipient_phone)))
                 ELSE CONCAT('unknown:',o.id) END buyer_key,
            CASE WHEN o.user_id IS NOT NULL OR NULLIF(LTRIM(RTRIM(o.recipient_phone)),'') IS NOT NULL THEN 1 ELSE 0 END identified
          FROM orders o LEFT JOIN history h ON h.order_id=o.id LEFT JOIN item_totals t ON t.order_id=o.id
        ), returned AS (
          SELECT r.id,r.order_id,r.request_code,r.refund_amount,r.status,
            DATEADD(minute,:jdbcOffset,r.received_at) received_at,DATEADD(minute,:jdbcOffset,r.completed_at) completed_at,
            f.delivered_at, f.buyer_key, f.recipient_name, f.order_code,
            COALESCE(x.quantity,0) quantity, COALESCE(x.cost,0) cost
          FROM return_requests r JOIN facts f ON f.id=r.order_id
          OUTER APPLY (SELECT SUM(CAST(i.quantity AS BIGINT)) quantity,
            SUM(CASE WHEN i.item_condition='INTACT' THEN i.unit_cost*i.quantity ELSE 0 END) cost
            FROM return_items i WHERE i.return_request_id=r.id) x
        ), events AS (
          SELECT delivered_at at, gross, promotion_discount, discount_amount voucher_discount,
            CAST(0 AS DECIMAL(38,2)) returned_goods, cost cogs, shipping_fee shipping,
            CAST(0 AS DECIMAL(38,2)) cash_in, CAST(0 AS DECIMAL(38,2)) cash_out,
            CAST(0 AS BIGINT) created_orders, CAST(1 AS BIGINT) delivered_orders,
            CAST(0 AS BIGINT) cancelled_orders, quantity sold_quantity
          FROM facts WHERE delivered_at IS NOT NULL
          UNION ALL SELECT received_at,0,0,0,refund_amount,-cost,0,0,0,0,0,0,-quantity
            FROM returned WHERE received_at IS NOT NULL AND delivered_at IS NOT NULL
          UNION ALL SELECT paid_at,0,0,0,0,0,0,total_amount,0,0,0,0,0 FROM facts WHERE paid_at IS NOT NULL
          UNION ALL SELECT refunded_at,0,0,0,0,0,0,0,total_amount,0,0,0,0 FROM facts WHERE refunded_at IS NOT NULL
          UNION ALL SELECT completed_at,0,0,0,0,0,0,0,refund_amount,0,0,0,0 FROM returned WHERE completed_at IS NOT NULL
          UNION ALL SELECT created_at,0,0,0,0,0,0,0,0,1,0,CASE WHEN order_status='CANCELLED' THEN 1 ELSE 0 END,0 FROM facts
        )
        """;

    MapSqlParameterSource params(DashboardQuery q) {
        var zone = ZoneId.of("Asia/Ho_Chi_Minh");
        return new MapSqlParameterSource()
                .addValue("jdbcOffset", ZoneId.systemDefault().getRules().getOffset(q.start().atStartOfDay(ZoneOffset.UTC).toInstant()).getTotalSeconds()/60)
                .addValue("start", LocalDateTime.ofInstant(q.start().atStartOfDay(zone).toInstant(),ZoneOffset.UTC))
                .addValue("end", LocalDateTime.ofInstant(q.end().plusDays(1).atStartOfDay(zone).toInstant(),ZoneOffset.UTC))
                .addValue("previous", LocalDateTime.ofInstant(q.previousStart().atStartOfDay(zone).toInstant(),ZoneOffset.UTC))
                .addValue("q", "%" + q.q().replace("!", "!!").replace("%", "!%").replace("_", "!_").replace("[", "![") + "%")
                .addValue("category", q.category()).addValue("status", q.status())
                .addValue("offset", (long) q.page()*q.size()).addValue("size", q.size());
    }

    public List<Map<String,Object>> daily(DashboardQuery q) {
        return jdbc.queryForList(FACTS + """
          SELECT CONVERT(varchar(10),DATEADD(hour,7,at),23) day,
            SUM(gross) grossGoods,SUM(promotion_discount) promotionDiscount,SUM(voucher_discount) voucherDiscount,
            SUM(returned_goods) returnedGoods,SUM(cogs) cogs,SUM(shipping) shipping,SUM(cash_in) cashIn,SUM(cash_out) cashOut,
            SUM(created_orders) createdOrders,SUM(delivered_orders) deliveredOrders,
            SUM(cancelled_orders) cancelledOrders,SUM(sold_quantity) soldQuantity
          FROM events WHERE at>=:previous AND at<:end
          GROUP BY CONVERT(varchar(10),DATEADD(hour,7,at),23) ORDER BY day
          """, params(q));
    }

    public Map<String,Object> current(DashboardQuery q) {
        return jdbc.queryForMap(FACTS + """
          SELECT
            (SELECT COUNT_BIG(*) FROM product_variants WHERE stock_quantity-reserved_quantity<=5) lowStock,
            (SELECT COALESCE(SUM(CAST(stock_quantity AS BIGINT)),0) FROM product_variants) stock,
            (SELECT COALESCE(SUM(CAST(reserved_quantity AS BIGINT)),0) FROM product_variants) reserved,
            (SELECT COALESCE(SUM(stock_quantity*cost_price),0) FROM product_variants) stockValue,
            (SELECT COALESCE(SUM(CASE WHEN g.total_amount-g.returned_amount-COALESCE(p.paid,0)>0
              THEN g.total_amount-g.returned_amount-COALESCE(p.paid,0) ELSE 0 END),0)
              FROM goods_receipts g OUTER APPLY (SELECT SUM(amount) paid FROM supplier_payments WHERE receipt_id=g.id) p
              WHERE g.status='POSTED') currentDebt,
            (SELECT COALESCE(SUM(total_amount-returned_amount),0) FROM goods_receipts
              WHERE status='POSTED' AND posted_at>=:start AND posted_at<:end) postedValue,
            (SELECT COUNT_BIG(*) FROM return_requests WHERE status='RECEIVED' AND refund_amount>0) pendingRefunds,
            (SELECT COUNT_BIG(*) FROM orders WHERE order_status='CONFIRMED') awaitingShipment,
            (SELECT COUNT_BIG(*) FROM (SELECT buyer_key FROM facts WHERE identified=1 AND paid_at>=:start AND paid_at<:end GROUP BY buyer_key) b) purchasingBuyers,
            (SELECT COUNT_BIG(*) FROM (SELECT buyer_key FROM facts WHERE identified=1 AND paid_at IS NOT NULL GROUP BY buyer_key
               HAVING MIN(paid_at)>=:start AND MIN(paid_at)<:end) b) newBuyers,
            (SELECT COALESCE(SUM(cost),0) FROM returned WHERE delivered_at IS NOT NULL AND received_at>=:start AND received_at<:end) costReversal,
            (SELECT COUNT_BIG(*) FROM facts WHERE payment_status IN ('PAID','REFUND_PENDING','REFUNDED') AND paid_at IS NULL) missingPaymentDates,
            (SELECT COUNT_BIG(*) FROM facts WHERE order_status='CANCELLED' AND payment_status='REFUNDED' AND refunded_at IS NULL) missingRefundDates,
            (SELECT COUNT_BIG(*) FROM facts WHERE delivered_at IS NULL AND (order_status='DELIVERED' OR (order_status='RETURNED'
              AND NOT EXISTS(SELECT 1 FROM order_histories h WHERE h.order_id=facts.id AND h.new_status='SHIPPED')))) missingDeliveryDates
          """, params(q));
    }

    public List<String> categories() {
        return jdbc.queryForList("SELECT DISTINCT name FROM categories ORDER BY name", Map.of(), String.class);
    }

    public Map<String,Long> distribution(DashboardQuery q) {
        var result = new LinkedHashMap<String,Long>();
        jdbc.query(FACTS+"SELECT order_status,COUNT_BIG(*) n FROM facts WHERE created_at>=:start AND created_at<:end GROUP BY order_status",
                params(q), rs -> { result.put(rs.getString(1), rs.getLong(2)); });
        return result;
    }

    public record ReportSpec(List<String> columns, List<Integer> moneyColumns, String sql, String sort, String note) {}
    public record TablePage(List<String> columns, List<List<String>> rows, long totalElements, String note) {}

    public TablePage table(DashboardQuery q, ReportSpec spec) {
        String search = String.join(",N' ',", java.util.stream.IntStream.range(0,spec.columns().size())
                .mapToObj(i -> "COALESCE(CONVERT(nvarchar(max),c"+i+"),N'')").toList());
        // CONCAT requires at least two arguments; all report specifications have >=2 columns.
        String base = FACTS + ", report AS (" + spec.sql() + "), filtered AS (SELECT * FROM report WHERE CONCAT(" + search + ") LIKE :q ESCAPE '!') ";
        var parameters = params(q);
        long count = Objects.requireNonNull(jdbc.queryForObject(base+"SELECT COUNT_BIG(*) FROM filtered",parameters,Long.class));
        var rows = jdbc.queryForList(base+"SELECT * FROM filtered ORDER BY "+spec.sort()+" OFFSET :offset ROWS FETCH NEXT :size ROWS ONLY",parameters);
        var format = java.text.NumberFormat.getNumberInstance(Locale.forLanguageTag("vi-VN"));
        format.setMaximumFractionDigits(2);
        List<List<String>> cells = rows.stream().map(r -> java.util.stream.IntStream.range(0,spec.columns().size()).mapToObj(i -> {
            Object v = r.get("c"+i);
            return v == null ? "—" : spec.moneyColumns().contains(i) ? format.format(v)+" đ" : v.toString();
        }).toList()).toList();
        return new TablePage(spec.columns(),cells,count,spec.note());
    }
}
