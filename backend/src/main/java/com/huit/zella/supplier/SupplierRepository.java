package com.huit.zella.supplier;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;

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

    @Query("""
            select s from Supplier s
                where (:active is null or s.isActive = :active)
                and (:query = '' or lower(s.name) like lower(concat('%', :query, '%'))
                    or lower(s.code) like lower(concat('%', :query, '%'))
                    or lower(s.contactPerson) like lower(concat('%', :query, '%'))
                    or lower(s.contactEmail) like lower(concat('%', :query, '%'))
                    or lower(s.phone) like lower(concat('%', :query, '%')))
            """)
    Page<Supplier> search(@Param("query") String query, @Param("active") Boolean active, Pageable pageable);
}
