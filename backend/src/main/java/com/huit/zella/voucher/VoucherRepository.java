package com.huit.zella.voucher;
import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;
import java.util.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
public interface VoucherRepository extends JpaRepository<Voucher,Long> {
    List<Voucher> findByOwnerIsNullAndRedeemableFalseOrderByIdDesc();
    List<Voucher> findByOwnerIsNullOrderByIdDesc();
    org.springframework.data.domain.Page<Voucher> findBySourceRewardId(Long sourceRewardId,org.springframework.data.domain.Pageable pageable);
    boolean existsByCodeIgnoreCaseAndIdNot(String code,Long id);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select v from Voucher v where v.id=:id") Optional<Voucher> lock(@Param("id") Long id);
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select v from Voucher v where v.code=:code") Optional<Voucher> lockCode(@Param("code") String code);
    Optional<Voucher> findByRedemptionKey(String key);
    @Query("select v from Voucher v where v.redeemable=true and v.active=true and v.owner is null and v.startDate<=:now and v.endDate>:now and (v.usageLimit is null or v.usedCount<v.usageLimit)")
    List<Voucher> rewards(@Param("now") LocalDateTime now);
    org.springframework.data.domain.Page<Voucher> findByOwnerUserId(Long userId,org.springframework.data.domain.Pageable pageable);
}
