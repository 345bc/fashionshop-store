package com.huit.zella.orderreturn;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface ReturnRepository extends JpaRepository<ReturnRequest, Long> {
    List<ReturnRequest> findByOrderIdOrderByIdDesc(Long orderId);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from ReturnRequest r where r.id = :id")
    Optional<ReturnRequest> findByIdForUpdate(@Param("id") Long id);
    @Query("select r.order.id from ReturnRequest r where r.id = :id")
    Optional<Long> findOrderId(@Param("id") Long id);
    @Query("select coalesce(sum(i.quantity),0) from ReturnItem i where i.orderItem.id = :id and i.request.status not in (com.huit.zella.orderreturn.ReturnStatus.CANCELLED, com.huit.zella.orderreturn.ReturnStatus.REJECTED)")
    Long committedQuantity(@Param("id") Long orderItemId);
}

