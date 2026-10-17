package com.huit.zella.payment.vnpay;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import java.util.List;
import java.util.Optional;

public interface PaymentRefundRepository extends JpaRepository<PaymentRefund, Long> {
    Optional<PaymentRefund> findFirstByTargetOrderByIdDesc(String target);
    List<PaymentRefund> findByOrderIdOrderByIdDesc(Long orderId);
    @Query("select r.orderId from PaymentRefund r where r.id=:id")
    Optional<Long> findOrderIdById(Long id);
}
