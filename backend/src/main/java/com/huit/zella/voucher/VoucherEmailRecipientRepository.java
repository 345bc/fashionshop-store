package com.huit.zella.voucher;

import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.List;

public interface VoucherEmailRecipientRepository extends JpaRepository<VoucherEmailRecipient, Long> {
    @Query("select r.email from VoucherEmailRecipient r where r.voucherId = :voucherId")
    List<String> queuedEmails(@Param("voucherId") Long voucherId);
}
