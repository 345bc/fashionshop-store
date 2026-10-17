package com.huit.zella.dashboard;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static com.huit.zella.dashboard.DashboardRepository.*;

@Service @RequiredArgsConstructor @Transactional(readOnly = true)
public class DashboardService {
    private final DashboardRepository repository;
    private static final List<String> METRICS = List.of("grossGoods","promotionDiscount","voucherDiscount","returnedGoods",
            "cogs","shipping","cashIn","cashOut","createdOrders","deliveredOrders","cancelledOrders","soldQuantity");

    public Map<String,Object> report(DashboardQuery q) {
        var daily = repository.daily(q);
        var byDay = new HashMap<LocalDate,Map<String,Object>>();
        daily.forEach(d -> byDay.put(LocalDate.parse(d.get("day").toString()),d));
        var summary = aggregate(daily,q.start(),q.end());
        var previous = aggregate(daily,q.previousStart(),q.start().minusDays(1));
        List<Map<String,Object>> trend = new ArrayList<>();
        for (LocalDate day=q.start(),old=q.previousStart(); !day.isAfter(q.end()); day=day.plusDays(1),old=old.plusDays(1)) {
            trend.add(Map.of("date",day.toString(),"current",net(byDay.getOrDefault(day,Map.of())),
                    "previous",net(byDay.getOrDefault(old,Map.of()))));
        }
        var current = repository.current(q);
        var table = repository.table(q,spec(q));
        List<String> warnings = new ArrayList<>();
        if (number(current,"missingPaymentDates").signum()>0)
            warnings.add("Có đơn đã thu tiền thiếu mốc thanh toán trong lịch sử; các đơn này chưa được tính vào thu tiền/người mua theo kỳ.");
        if (number(current,"missingDeliveryDates").signum()>0)
            warnings.add("Có đơn giao thiếu mốc giao trong lịch sử; không dùng ngày tạo đơn để thay thế ngày giao.");
        if (number(current,"missingRefundDates").signum()>0)
            warnings.add("Có đơn hủy đã hoàn tiền nhưng thiếu mốc hoàn trong lịch sử; các đơn này chưa được tính vào hoàn tiền theo kỳ.");
        return Map.ofEntries(Map.entry("summary",summary),Map.entry("previous",previous),Map.entry("trend",trend),
                Map.entry("current",current),Map.entry("table",table),Map.entry("categories",repository.categories()),
                Map.entry("distribution",repository.distribution(q)),Map.entry("warnings",warnings),
                Map.entry("timezone","Asia/Ho_Chi_Minh"),Map.entry("generatedAt",Instant.now().toString()));
    }

    static Map<String,Object> aggregate(List<Map<String,Object>> days, LocalDate start, LocalDate end) {
        var result = new LinkedHashMap<String,Object>();
        METRICS.forEach(k -> result.put(k,BigDecimal.ZERO));
        days.stream().filter(d -> {
            var date=LocalDate.parse(d.get("day").toString()); return !date.isBefore(start)&&!date.isAfter(end);
        }).forEach(d -> METRICS.forEach(k -> result.put(k,number(result,k).add(number(d,k)))));
        return result;
    }
    static BigDecimal number(Map<String,?> values,String key) {
        Object value=values.get(key); return value==null?BigDecimal.ZERO:new BigDecimal(value.toString());
    }
    static BigDecimal net(Map<String,?> m) {
        return number(m,"grossGoods").subtract(number(m,"promotionDiscount")).subtract(number(m,"voucherDiscount")).subtract(number(m,"returnedGoods"));
    }

    private ReportSpec report(String[] columns,int[] money,String sql,String sort,String note) {
        return new ReportSpec(List.of(columns),Arrays.stream(money).boxed().toList(),sql,sort,note);
    }
    ReportSpec spec(DashboardQuery q) {
        return switch(q.section()) {
            case overview, revenue -> report(new String[]{"Ngày","Doanh thu thuần hàng","Giá vốn","Lợi nhuận gộp","Thu từ khách","Đã hoàn tiền"},new int[]{1,2,3,4,5},"""
                SELECT CONVERT(varchar(10),DATEADD(hour,7,at),23) c0,
                  SUM(gross-promotion_discount-voucher_discount-returned_goods) c1,SUM(cogs) c2,
                  SUM(gross-promotion_discount-voucher_discount-returned_goods-cogs) c3,SUM(cash_in) c4,SUM(cash_out) c5
                FROM events WHERE at>=:start AND at<:end GROUP BY CONVERT(varchar(10),DATEADD(hour,7,at),23)
                ""","c0 DESC","Doanh thu theo ngày giao/nhận trả; thu và hoàn theo lịch sử thanh toán, không gồm phí vận chuyển trong doanh thu. Ngày không phát sinh có giá trị 0 trên biểu đồ.");
            case orders -> report(new String[]{"Mã đơn","Khách hàng","Ngày đặt","Tổng tiền","Trạng thái","Thanh toán"},new int[]{3},"""
                SELECT order_code c0,recipient_name c1,CONVERT(varchar(10),DATEADD(hour,7,created_at),23) c2,
                  total_amount c3,
                  CASE order_status WHEN 'PENDING' THEN N'Chờ thanh toán' WHEN 'CONFIRMED' THEN N'Đã thanh toán'
                    WHEN 'SHIPPED' THEN N'Đang giao' WHEN 'DELIVERED' THEN N'Đã giao' WHEN 'CANCELLED' THEN N'Đã hủy'
                    WHEN 'RETURNED' THEN N'Đã trả hàng' ELSE order_status END c4,
                  CASE payment_status WHEN 'PAID' THEN N'Đã thu tiền' WHEN 'REFUNDED' THEN N'Đã hoàn tiền'
                    WHEN 'REFUND_PENDING' THEN N'Chờ hoàn tiền' WHEN 'PENDING' THEN N'Chưa thanh toán'
                    WHEN 'EXPIRED' THEN N'Hết hạn thanh toán' ELSE payment_status END c5,id sort_id,created_at sort_date
                FROM facts WHERE created_at>=:start AND created_at<:end AND (:status IS NULL OR order_status=:status)
                ""","sort_date DESC,sort_id DESC","Đơn tạo trong kỳ, trạng thái hiện tại. Đơn chưa giao không tính doanh thu.");
            case returns -> report(new String[]{"Phiếu trả","Đơn gốc","Ngày nhận trả","SL trả","Giá trị hoàn","Trạng thái","Ngày hoàn"},new int[]{4},"""
                SELECT request_code c0,order_code c1,CONVERT(varchar(10),DATEADD(hour,7,received_at),23) c2,
                  quantity c3,refund_amount c4,CASE status WHEN 'RECEIVED' THEN N'Đã nhận / chờ hoàn'
                    WHEN 'COMPLETED' THEN N'Đã hoàn tất' ELSE status END c5,
                  CONVERT(varchar(10),DATEADD(hour,7,completed_at),23) c6,id sort_id,received_at sort_date
                FROM returned WHERE received_at>=:start AND received_at<:end
                ""","sort_date DESC,sort_id DESC","Phiếu đã nhận trong kỳ. Hàng giao thất bại có thể hoàn cả vận chuyển nhưng không đảo doanh thu chưa ghi nhận. Chỉ hoàn đã hoàn tất mới tính tiền chi.");
            case products -> productReport();
            case inventory -> report(new String[]{"Sản phẩm / SKU","Danh mục","Tồn","Đã giữ","Có thể bán","Giá vốn / đơn vị","Giá trị tồn","Cảnh báo"},new int[]{5,6},"""
                SELECT CONCAT(p.name,N' / ',v.sku) c0,c.name c1,v.stock_quantity c2,v.reserved_quantity c3,
                  v.stock_quantity-v.reserved_quantity c4,v.cost_price c5,v.stock_quantity*v.cost_price c6,
                  CASE WHEN v.stock_quantity-v.reserved_quantity<=0 THEN N'Hết hàng'
                    WHEN v.stock_quantity-v.reserved_quantity<=5 THEN N'Sắp hết' ELSE N'Đủ hàng' END c7,v.id sort_id
                FROM product_variants v JOIN products p ON p.id=v.product_id JOIN categories c ON c.id=p.category_id
                WHERE (:category IS NULL OR c.name=:category)
                ""","c4,sort_id","Tồn hiện tại, không lọc theo ngày; gồm SKU đang tạm ngừng bán. Có thể bán = tồn − giữ. Giá trị tồn theo giá vốn hiện tại.");
            case customers -> report(new String[]{"Người mua","Loại khách","Nhóm khách","Đơn trả tiền","Đơn giao","Doanh thu thuần"},new int[]{5},"""
                SELECT MAX(f.recipient_name) c0,CASE WHEN MAX(CASE WHEN user_id IS NOT NULL THEN 1 ELSE 0 END)=1
                    THEN N'Có tài khoản' ELSE N'Vãng lai' END c1,
                  CASE WHEN MIN(paid_at)>=:start AND MIN(paid_at)<:end THEN N'Mới trong kỳ' ELSE N'Đã mua trước kỳ' END c2,
                  SUM(CASE WHEN paid_at>=:start AND paid_at<:end THEN 1 ELSE 0 END) c3,
                  SUM(CASE WHEN delivered_at>=:start AND delivered_at<:end THEN 1 ELSE 0 END) c4,
                  SUM(CASE WHEN delivered_at>=:start AND delivered_at<:end THEN goods ELSE 0 END)
                    -COALESCE(MAX(r.refund),0) c5,f.buyer_key sort_id
                FROM facts f LEFT JOIN (SELECT buyer_key,SUM(refund_amount) refund FROM returned
                  WHERE delivered_at IS NOT NULL AND received_at>=:start AND received_at<:end GROUP BY buyer_key) r ON r.buyer_key=f.buyer_key
                WHERE identified=1 GROUP BY f.buyer_key HAVING
                  SUM(CASE WHEN (paid_at>=:start AND paid_at<:end) OR (delivered_at>=:start AND delivered_at<:end) THEN 1 ELSE 0 END)>0
                    OR MAX(r.refund) IS NOT NULL
                ""","c5 DESC,sort_id","Khách có tài khoản theo user_id, vãng lai theo số điện thoại đặt hàng; không ghép tự động tài khoản với đơn vãng lai. Khách mới dựa trên toàn bộ lịch sử thanh toán hiện có; đơn thiếu định danh không đếm thành người mới.");
            case purchases -> report(new String[]{"Phiếu nhập","Nhà cung cấp","Ngày ghi sổ","Trạng thái","Giá trị phiếu","Trả NCC","Đã trả tiền","Còn nợ"},new int[]{4,5,6,7},"""
                SELECT g.code c0,s.name c1,CONVERT(varchar(10),SWITCHOFFSET(g.posted_at,'+07:00'),23) c2,N'Đã nhập kho' c3,
                  g.total_amount c4,g.returned_amount c5,COALESCE(p.paid,0) c6,
                  CASE WHEN g.total_amount-g.returned_amount-COALESCE(p.paid,0)>0
                    THEN g.total_amount-g.returned_amount-COALESCE(p.paid,0) ELSE 0 END c7,g.id sort_id,g.posted_at sort_date
                FROM goods_receipts g JOIN suppliers s ON s.id=g.supplier_id
                OUTER APPLY (SELECT SUM(amount) paid FROM supplier_payments WHERE receipt_id=g.id) p
                WHERE g.status='POSTED' AND g.posted_at>=:start AND g.posted_at<:end
                ""","sort_date DESC,sort_id DESC","Phiếu POSTED theo ngày ghi sổ. Đã trả/còn nợ là lũy kế hiện tại, không phải chi tiền trong kỳ; khoản đã trả thừa sau trả NCC không hiển thị thành nợ âm.");
            case promotions -> report(new String[]{"Ưu đãi","Loại","Đơn giao áp dụng","Tiền giảm trên đơn giao","Đơn trả tiền dùng mã"},new int[]{3},"""
                SELECT v.code c0,N'Voucher' c1,SUM(CASE WHEN f.delivered_at>=:start AND f.delivered_at<:end THEN 1 ELSE 0 END) c2,
                  SUM(CASE WHEN f.delivered_at>=:start AND f.delivered_at<:end THEN f.discount_amount-f.membership_discount_amount ELSE 0 END) c3,
                  SUM(CASE WHEN f.paid_at>=:start AND f.paid_at<:end THEN 1 ELSE 0 END) c4,CONCAT('v:',v.id) sort_id
                FROM facts f JOIN vouchers v ON v.id=f.voucher_id
                WHERE (f.delivered_at>=:start AND f.delivered_at<:end) OR (f.paid_at>=:start AND f.paid_at<:end) GROUP BY v.id,v.code
                UNION ALL SELECT N'Giảm giá sản phẩm',N'Khuyến mãi sản phẩm',COUNT_BIG(*),COALESCE(SUM(promotion_discount),0),0,'product'
                  FROM facts WHERE delivered_at>=:start AND delivered_at<:end AND promotion_discount>0 HAVING COUNT_BIG(*)>0
                UNION ALL SELECT N'Ưu đãi thành viên',N'Thành viên',COUNT_BIG(*),COALESCE(SUM(membership_discount_amount),0),0,'membership'
                  FROM facts WHERE delivered_at>=:start AND delivered_at<:end AND membership_discount_amount>0 HAVING COUNT_BIG(*)>0
                ""","c3 DESC,sort_id","Tiền giảm snapshot trên đơn giao, trước đảo hàng trả. Một đơn có thể thuộc nhiều nhóm; không cộng số đơn giữa các nhóm. Không suy diễn hiệu quả tăng trưởng.");
        };
    }

    private ReportSpec productReport() {
        // Allocate order-level reductions and return refunds to SKU lines. The last line absorbs rounding.
        return report(new String[]{"Sản phẩm","SKU","Danh mục","SL bán ròng","Doanh thu thuần","Giá vốn","Lợi nhuận gộp","SL trả"},new int[]{4,5,6},"""
          SELECT MAX(x.name) c0,x.sku c1,MAX(x.category) c2,SUM(x.qty) c3,SUM(x.revenue) c4,
            SUM(x.cost) c5,SUM(x.revenue-x.cost) c6,SUM(x.returned_qty) c7,x.variant_id sort_id
          FROM (
            SELECT p.name,i.sku,c.name category,i.variant_id,CAST(i.quantity AS BIGINT) qty,
              CASE WHEN ROW_NUMBER() OVER(PARTITION BY i.order_id ORDER BY i.id DESC)=1
                THEN f.goods-SUM(ROUND(i.unit_price*i.quantity*f.goods/NULLIF(f.subtotal,0),2)) OVER(PARTITION BY i.order_id)
                  +ROUND(i.unit_price*i.quantity*f.goods/NULLIF(f.subtotal,0),2)
                ELSE ROUND(i.unit_price*i.quantity*f.goods/NULLIF(f.subtotal,0),2) END revenue,
              i.unit_cost*i.quantity cost,CAST(0 AS BIGINT) returned_qty
            FROM order_items i JOIN facts f ON f.id=i.order_id JOIN products p ON p.id=i.product_id
              JOIN categories c ON c.id=p.category_id WHERE f.delivered_at>=:start AND f.delivered_at<:end
            UNION ALL
            SELECT z.name,z.sku,z.category,z.variant_id,-z.quantity,
              -CASE WHEN z.last_line=1 THEN z.refund_amount-SUM(z.allocated) OVER(PARTITION BY z.return_request_id)+z.allocated ELSE z.allocated END,
              -z.cost,z.quantity FROM (
              SELECT p.name,i.sku,c.name category,i.variant_id,r.id return_request_id,ri.quantity,r.refund_amount,
                ROW_NUMBER() OVER(PARTITION BY r.id ORDER BY ri.id DESC) last_line,
                ROUND(r.refund_amount*(i.unit_price*ri.quantity)/NULLIF(SUM(i.unit_price*ri.quantity) OVER(PARTITION BY r.id),0),2) allocated,
                CASE WHEN ri.item_condition='INTACT' THEN ri.unit_cost*ri.quantity ELSE 0 END cost
              FROM return_items ri JOIN returned r ON r.id=ri.return_request_id JOIN order_items i ON i.id=ri.order_item_id
                JOIN products p ON p.id=i.product_id JOIN categories c ON c.id=p.category_id
              WHERE r.delivered_at IS NOT NULL AND r.received_at>=:start AND r.received_at<:end
            ) z
          ) x WHERE (:category IS NULL OR x.category=:category) GROUP BY x.variant_id,x.sku
          ""","c4 DESC,sort_id","Xếp theo doanh thu thuần của SKU. Phân bổ giảm giá/tiền hoàn theo giá trị dòng, dòng cuối nhận phần lẻ. Hàng trả nhận kỳ này có thể thuộc đơn giao kỳ trước; số ròng có thể âm.");
    }
}
