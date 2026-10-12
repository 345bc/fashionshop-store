package com.huit.zella.orderreturn;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface ReturnRepository extends JpaRepository<ReturnRequest, Long> {
    @Query("select coalesce(sum(i.quantity*i.orderItem.originalUnitPrice),0) from ReturnItem i where i.request.order.id=:id and i.request.status in (com.huit.zella.orderreturn.ReturnStatus.RECEIVED,com.huit.zella.orderreturn.ReturnStatus.COMPLETED)")
    java.math.BigDecimal receivedOriginalValue(@Param("id") Long orderId);
    @Query("select coalesce(sum(i.quantity),0) from ReturnItem i where i.orderItem.id=:id and i.request.status in (com.huit.zella.orderreturn.ReturnStatus.RECEIVED,com.huit.zella.orderreturn.ReturnStatus.COMPLETED)")
    Long receivedQuantity(@Param("id") Long orderItemId);
    @Query("select coalesce(sum(r.refundAmount),0) from ReturnRequest r where r.order.id=:id and r.status in (com.huit.zella.orderreturn.ReturnStatus.RECEIVED,com.huit.zella.orderreturn.ReturnStatus.COMPLETED)")
    java.math.BigDecimal receivedRefund(@Param("id") Long orderId);
    @Query("select count(r) from ReturnRequest r where r.order.id=:id and r.status=com.huit.zella.orderreturn.ReturnStatus.RECEIVED and r.refundAmount>0")
    long pendingRefundCount(@Param("id") Long orderId);
    @Query("select coalesce(sum(i.quantity*i.orderItem.unitPrice),0) from ReturnItem i where i.request.order.id=:id and i.request.status in (com.huit.zella.orderreturn.ReturnStatus.RECEIVED,com.huit.zella.orderreturn.ReturnStatus.COMPLETED)")
    java.math.BigDecimal receivedValue(@Param("id") Long orderId);
    List<ReturnRequest> findByOrderIdOrderByIdDesc(Long orderId);
    @EntityGraph(attributePaths = "order")
    List<ReturnRequest> findByOrderIdInOrderByIdDesc(List<Long> orderIds);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from ReturnRequest r where r.id = :id")
    Optional<ReturnRequest> findByIdForUpdate(@Param("id") Long id);
    @Query("select r.order.id from ReturnRequest r where r.id = :id")
    Optional<Long> findOrderId(@Param("id") Long id);
    @Query("select coalesce(sum(i.quantity),0) from ReturnItem i where i.orderItem.id = :id and i.request.status not in (com.huit.zella.orderreturn.ReturnStatus.CANCELLED, com.huit.zella.orderreturn.ReturnStatus.REJECTED)")
    Long committedQuantity(@Param("id") Long orderItemId);
}

