package com.huit.zella.dashboard;

import com.huit.zella.inventory.WarehouseFixture;
import com.huit.zella.order.*;
import com.huit.zella.orderreturn.*;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest(properties="app.order.expiration.enabled=false") @Transactional
class DashboardWorkflowTest extends WarehouseFixture {
    @Autowired DashboardService dashboard;
    final LocalDate day = LocalDate.of(2001,2,3);
    final LocalDateTime before = LocalDateTime.of(2001,2,2,10,0);
    final LocalDateTime during = LocalDateTime.of(2001,2,3,10,0);

    DashboardQuery query(DashboardQuery.Section section,String search) {
        return new DashboardQuery(day,day,section,search,null,null,0,100);
    }
    Order order(String suffix, boolean delivered) {
        var o=new Order(); o.setCode("DASH-"+suffix+UUID.randomUUID().toString().substring(0,8));
        o.setRecipientName("Dashboard test");o.setRecipientPhone("0901234567");o.setAddress("Test");
        o.setCreatedAt(before);o.setPaymentStatus("PAID");o.setPaymentMethod("ONLINE");
        o.setSubtotal(new BigDecimal("300000"));o.setOriginalSubtotal(new BigDecimal("450000"));
        o.setDiscountAmount(new BigDecimal("30000"));o.setMembershipDiscountAmount(new BigDecimal("5000"));
        o.setShippingFee(new BigDecimal("30000"));o.setTotalAmount(new BigDecimal("300000"));
        o.setStatus(delivered?OrderStatus.DELIVERED:OrderStatus.CONFIRMED);em.persist(o);
        item(o,2,"40000");item(o,1,"60000");
        history(o,"PENDING","CONFIRMED",before);
        if(delivered) {history(o,"SHIPPED","DELIVERED",during);history(o,"DELIVERED","DELIVERED",during.plusHours(1));}
        return o;
    }
    void item(Order o,int qty,String cost) {
        var i=new OrderItem();i.setOrder(o);i.setProduct(variant.getProduct());i.setVariant(variant);
        i.setProductName("Test product");i.setSku(variant.getSku());i.setQuantity(qty);
        i.setOriginalUnitPrice(new BigDecimal("150000"));i.setUnitPrice(new BigDecimal("100000"));
        i.setUnitCost(new BigDecimal(cost));em.persist(i);o.getItems().add(i);
    }
    void history(Order o,String from,String to,LocalDateTime time) {
        var h=new OrderHistory();h.setOrder(o);h.setOldStatus(from);h.setNewStatus(to);h.setCreatedAt(time);h.setCreatedBy(actor);em.persist(h);
    }
    ReturnRequest returned(Order o,boolean intact, boolean completed,BigDecimal amount) {
        var r=new ReturnRequest();r.setCode("RET-"+UUID.randomUUID().toString().substring(0,8));r.setOrder(o);
        r.setStatus(completed?ReturnStatus.COMPLETED:ReturnStatus.RECEIVED);r.setReceivedAt(during);r.setRefundAmount(amount);
        if(completed)r.setCompletedAt(during);em.persist(r);
        var i=new ReturnItem();i.setRequest(r);i.setOrderItem(o.getItems().getFirst());i.setQuantity(1);
        i.setItemCondition(intact?"INTACT":"DAMAGED");i.setUnitCost(new BigDecimal("40000"));em.persist(i);
        return r;
    }
    Map<?,?> summary(Map<String,Object> result) {return (Map<?,?>)result.get("summary");}
    BigDecimal n(Map<?,?> m,String key) {return new BigDecimal(m.get(key).toString());}
    @Test void multiLineDeliveryAndReturnReconcileAcrossAllReportSections() {
        var sold=order("sold",true);returned(sold,true,false,new BigDecimal("90000"));
        order("pending",false);em.flush();
        var result=dashboard.report(query(DashboardQuery.Section.revenue,""));
        var s=summary(result);
        assertEquals(0,n(s,"grossGoods").compareTo(new BigDecimal("450000")));
        assertEquals(0,n(s,"returnedGoods").compareTo(new BigDecimal("90000")));
        assertEquals(0,n(s,"cogs").compareTo(new BigDecimal("100000")));
        assertEquals(0,n(s,"cashIn").compareTo(BigDecimal.ZERO)); // Paid in the preceding period.
        assertEquals(0,n(s,"cashOut").compareTo(BigDecimal.ZERO)); // Refund not completed.
        assertEquals(0,n(s,"deliveredOrders").compareTo(BigDecimal.ONE)); // Repeated delivery history is deduplicated.
        var products=(DashboardRepository.TablePage)dashboard.report(query(DashboardQuery.Section.products,variant.getSku())).get("table");
        assertEquals(1,products.totalElements());
        assertEquals("180.000 đ",products.rows().getFirst().get(4));
        assertEquals("100.000 đ",products.rows().getFirst().get(5));
        // Execute each SQL report against SQL Server, including empty result sets.
        for(var section:DashboardQuery.Section.values()) assertNotNull(dashboard.report(query(section,"")),section.name());
    }
    @Test void failedDeliveryReturnDoesNotReverseUnrecognizedRevenueOrCost() {
        var o=order("failed",false);o.setStatus(OrderStatus.RETURNED);
        returned(o,true,true,new BigDecimal("300000"));em.flush();
        var s=summary(dashboard.report(query(DashboardQuery.Section.revenue,"")));
        assertEquals(0,n(s,"returnedGoods").compareTo(BigDecimal.ZERO));
        assertEquals(0,n(s,"cogs").compareTo(BigDecimal.ZERO));
        assertEquals(0,n(s,"cashOut").compareTo(new BigDecimal("300000")));
    }
    @Test void vietnamDayBoundariesAndServerPaginationAreApplied() {
        var inside=order("inside",false);inside.setCreatedAt(day.atTime(16,59,59));
        var outside=order("outside",false);outside.setCreatedAt(day.atTime(17,0));em.flush();
        var result=dashboard.report(new DashboardQuery(day,day,DashboardQuery.Section.orders,"DASH-",null,null,0,1));
        var table=(DashboardRepository.TablePage)result.get("table");
        var raw=em.createNativeQuery("select convert(varchar(30),created_at,126) from orders where id in (:a,:b) order by id",String.class)
                .setParameter("a",inside.getId()).setParameter("b",outside.getId()).getResultList();
        assertEquals(1,table.totalElements(),raw.toString());assertEquals(inside.getCode(),table.rows().getFirst().getFirst());
        var empty=(DashboardRepository.TablePage)dashboard.report(query(DashboardQuery.Section.orders,"%_[")).get("table");
        assertEquals(0,empty.totalElements());
    }

    @Test void buyerCountUsesFirstPaymentAcrossAllHistoryAndDeduplicatesGuestPhone() {
        order("previous-purchase",false);
        var current=order("current-purchase",false);
        // Both helper orders have earlier payment history; move the second one's event into this period.
        em.createQuery("update OrderHistory h set h.createdAt=:at where h.order.id=:id")
                .setParameter("at",during).setParameter("id",current.getId()).executeUpdate();
        em.flush();
        var result=dashboard.report(query(DashboardQuery.Section.customers,""));
        var currentMetrics=(Map<?,?>)result.get("current");
        assertEquals(1,n(currentMetrics,"purchasingBuyers").intValue());
        assertEquals(0,n(currentMetrics,"newBuyers").intValue());
        assertEquals(300000,n(summary(result),"cashIn").intValue());
    }

    @Test void supplierDebtIsCurrentAndOverpaymentNeverBecomesNegativeDebt() {
        var beforeMetrics=(Map<?,?>)dashboard.report(query(DashboardQuery.Section.purchases,"")).get("current");
        var debt=n(beforeMetrics,"currentDebt");
        receipt("1000","200","900"); // 100 overpaid: receivable, not negative payable.
        receipt("500","50","100");
        em.flush();
        var afterMetrics=(Map<?,?>)dashboard.report(query(DashboardQuery.Section.purchases,"")).get("current");
        assertEquals(0,n(afterMetrics,"currentDebt").subtract(debt).compareTo(new BigDecimal("350")));
    }
    void receipt(String total,String returned,String paid) {
        var r=new com.huit.zella.goodsreceipt.GoodsReceipt();
        r.setCode("DASH-GR-"+UUID.randomUUID().toString().substring(0,8));r.setSupplier(supplier);r.setStatus("POSTED");
        r.setTotalAmount(new BigDecimal(total));r.setReturnedAmount(new BigDecimal(returned));r.setPostedAt(during.toInstant(ZoneOffset.UTC));em.persist(r);
        var payment=new com.huit.zella.goodsreceipt.SupplierPayment();payment.setReceipt(r);payment.setAmount(new BigDecimal(paid));
        payment.setPaymentMethod("TRANSFER");payment.setCreatedBy(actor);em.persist(payment);
    }
}
