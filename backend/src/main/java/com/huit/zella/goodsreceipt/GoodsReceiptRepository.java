package com.huit.zella.goodsreceipt;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;
public interface GoodsReceiptRepository extends JpaRepository<GoodsReceipt, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from GoodsReceipt r where r.id = :id")
    Optional<GoodsReceipt> findByIdForUpdate(@Param("id") Long id);
}
