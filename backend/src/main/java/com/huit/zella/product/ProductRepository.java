package com.huit.zella.product;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface ProductRepository extends JpaRepository<Product, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select product from Product product where product.id = :id")
    Optional<Product> findByIdForImageUpdate(@Param("id") Long id);

    boolean existsBySizeGuideId(Long sizeGuideId);
    boolean existsByCategoryId(Long categoryId);
    boolean existsBySupplierId(Long supplierId);
    boolean existsByNameIgnoreCase(String name);
    boolean existsBySlugIgnoreCase(String slug);

    boolean existsByNameIgnoreCaseAndIdNot(String name, Long id);
    boolean existsBySlugIgnoreCaseAndIdNot(String name, Long id);

    Page<Product> findByNameContainingIgnoreCase(String query, Pageable pageable);
}
