package com.huit.zella.order;

import org.springframework.data.domain.Page;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Long> {
    Page<Order> findByVoucherId(Long voucherId,Pageable pageable);
    @Query("""
            select o from Order o
            where exists (select r.id from ReturnRequest r where r.order = o and (:status is null or r.status = :status))
              and (:q = '' or lower(o.code) like lower(concat('%', :q, '%'))
                   or lower(o.recipientName) like lower(concat('%', :q, '%'))
                   or o.recipientPhone like concat('%', :q, '%'))
            """)
    Page<Order> searchReturnOrders(@Param("q") String q,
            @Param("status") com.huit.zella.orderreturn.ReturnStatus status, Pageable pageable);
    @Query("select o from Order o where o.customer.id = :userId and (:status is null or o.status = :status)")
    Page<Order> findCustomerOrders(@Param("userId") Long userId, @Param("status") OrderStatus status, Pageable pageable);
    @Query("select o from Order o where o.customer.id = :userId and o.status in (com.huit.zella.order.OrderStatus.DELIVERED, com.huit.zella.order.OrderStatus.RETURNED)")
    Page<Order> findPurchases(@Param("userId") Long userId, Pageable pageable);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from Order o where o.id = :id")
    Optional<Order> findByIdForUpdate(@Param("id") Long id);

    Optional<Order> findByCode(String code);
    Optional<Order> findByCheckoutTokenHash(String checkoutTokenHash);

    boolean existsByOnlineTransactionIdAndIdNot(String transactionId, Long id);

    @Query("select o.id from Order o where o.inventoryManaged = true and o.status = com.huit.zella.order.OrderStatus.PENDING and o.paymentStatus = 'PENDING' and o.paymentExpiresAt <= :now order by o.paymentExpiresAt, o.id")
    List<Long> findExpiredOrderIds(@Param("now") LocalDateTime now, Pageable pageable);

    @Query("""
            select o from Order o left join o.customer u left join u.customer c
                where (:status is null or o.status = :status)
                and (:query = '' or lower(o.code) like lower(concat('%', :query, '%'))
                    or lower(o.recipientName) like lower(concat('%', :query, '%'))
                    or lower(o.recipientPhone) like lower(concat('%', :query, '%'))
                    or lower(u.userName) like lower(concat('%', :query, '%'))
                    or lower(c.fullName) like lower(concat('%', :query, '%')))
            """)
    Page<Order> search(@Param("query") String query, @Param("status") OrderStatus status, Pageable pageable);
}
