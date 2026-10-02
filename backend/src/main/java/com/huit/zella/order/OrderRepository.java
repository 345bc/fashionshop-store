package com.huit.zella.order;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from Order o where o.id = :id")
    Optional<Order> findByIdForUpdate(@Param("id") Long id);

    Optional<Order> findByCode(String code);

    boolean existsByOnlineTransactionIdAndIdNot(String transactionId, Long id);

    @Query("select o.id from Order o where o.inventoryManaged = true and o.status = com.huit.zella.order.OrderStatus.PENDING and o.paymentStatus = 'PENDING' and o.paymentExpiresAt <= :now order by o.paymentExpiresAt, o.id")
    List<Long> findExpiredOrderIds(@Param("now") LocalDateTime now, Pageable pageable);
}
