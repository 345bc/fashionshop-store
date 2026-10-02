package com.huit.zella.productvariant;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface ProductVariantRepository extends JpaRepository<ProductVariant, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select variant from ProductVariant variant where variant.id = :id")
    Optional<ProductVariant> findByIdForInventoryUpdate(@Param("id") Long id);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select variant from ProductVariant variant where variant.id = :id")
    Optional<ProductVariant> findByIdForImageUpdate(@Param("id") Long id);

    boolean existsBySizeId(Integer sizeId);
    boolean existsByColorId(Integer colorId);
    boolean existsBySkuIgnoreCase(String sku);

    boolean existsBySkuIgnoreCaseAndIdNot(String sku, Long id);

    boolean existsByProductIdAndSizeIdAndColorId(Long productId, Integer sizeId, Integer colorId);

    boolean existsByProductIdAndSizeIdAndColorIdAndIdNot(Long productId, Integer sizeId, Integer colorId, Long id);

    Page<ProductVariant> findBySkuContainingIgnoreCase(String sku, Pageable pageable);

    Page<ProductVariant> findByProductId(Long productId, Pageable pageable);

    Page<ProductVariant> findByProductIdAndSkuContainingIgnoreCase(Long productId, String sku, Pageable pageable);
}
