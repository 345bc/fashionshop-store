package com.huit.zella.productvariant;

import com.huit.zella.variantimage.VariantImage;
import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
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

    @Query("""
            select v from ProductVariant v join v.product p join p.category c join v.size sz join v.color cl
            left join p.supplier s
            where (:supplierId is null or s.id = :supplierId)
              and (:status is null or (:status = 'out' and v.stockQuantity - v.reservedQuantity = 0)
                  or (:status = 'available' and v.stockQuantity - v.reservedQuantity > 0))
              and (:query = '' or lower(v.sku) like lower(concat('%', :query, '%'))
                  or lower(p.name) like lower(concat('%', :query, '%'))
                  or lower(c.name) like lower(concat('%', :query, '%'))
                  or lower(sz.name) like lower(concat('%', :query, '%'))
                  or lower(cl.name) like lower(concat('%', :query, '%')))
            """)
    Page<ProductVariant> searchInventory(@Param("query") String query, @Param("supplierId") Long supplierId,
            @Param("status") String status, Pageable pageable);


    @Query("""
        select v from ProductVariant v
        join fetch v.color
        where v.product.id in :productIds
          and v.isActive = true
        order by v.color.id, v.id
        """)
    List<ProductVariant> findCardVariants(
            @Param("productIds") List<Long> productIds
    );

    @Query("""
        select v from ProductVariant v
        join fetch v.color
        join fetch v.size
        where v.product.id = :productId
          and v.isActive = true
        order by v.color.id, v.size.id
        """)
    List<ProductVariant> findDetailVariants(@Param("productId") Long productId);
}
