package com.huit.zella.supplier;

import com.huit.zella.category.Category;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SupplierRepository extends JpaRepository<Supplier, Long> {
    Optional<Supplier> findByIdAndIsActiveTrue(Long id);
}
