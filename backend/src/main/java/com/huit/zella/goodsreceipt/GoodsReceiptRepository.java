package com.huit.zella.goodsreceipt;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;

import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface GoodsReceiptRepository extends JpaRepository<GoodsReceipt, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from GoodsReceipt r where r.id = :id")
    Optional<GoodsReceipt> findByIdForUpdate(@Param("id") Long id);

    @Query("""
            select r from GoodsReceipt r join r.supplier s
                where (:status is null or r.status = :status)
                and (:query = '' or lower(r.code) like lower(concat('%', :query, '%'))
                    or lower(s.name) like lower(concat('%', :query, '%')))
            """)
    Page<GoodsReceipt> search(@Param("query") String query, @Param("status") String status, Pageable pageable);
}
