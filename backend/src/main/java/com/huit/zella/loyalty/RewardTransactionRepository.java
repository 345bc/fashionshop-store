package com.huit.zella.loyalty;
import java.time.LocalDateTime;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
public interface RewardTransactionRepository extends JpaRepository<RewardTransaction,Long> {
    boolean existsByReferenceKey(String key);
    @Query("select r from RewardTransaction r where r.customer.user.id=:user and r.createdAt>=:from and r.createdAt<:to")
    Page<RewardTransaction> history(@Param("user") Long user, @Param("from") LocalDateTime from, @Param("to") LocalDateTime to, Pageable pageable);
}
