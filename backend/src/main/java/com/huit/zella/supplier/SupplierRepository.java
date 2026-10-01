package com.huit.zella.supplier;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface SupplierRepository extends JpaRepository<Supplier, Long> {
    Optional<Supplier> findByIdAndIsActiveTrue(Long id);
    boolean existsByCodeIgnoreCase(String code);
    boolean existsByCodeIgnoreCaseAndIdNot(String code, Long id);
    @Query(value = "select count(*) from goods_receipts where supplier_id = :supplierId", nativeQuery = true)
    long countGoodsReceipts(@Param("supplierId") Long supplierId);
}
