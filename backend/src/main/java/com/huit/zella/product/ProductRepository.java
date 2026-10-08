package com.huit.zella.product;

import jakarta.persistence.LockModeType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
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

    Page<Product> findByCategoryId(Long categoryId, Pageable pageable);

    Page<Product> findByCategoryIdAndNameContainingIgnoreCase(
            Long categoryId, String query, Pageable pageable
    );

    //    Card
    @Query("""
            select p from Product p
            where p.isActive = true
              and p.category.isActive = true
              and (:categoryId is null or p.category.id = :categoryId)
              and (:q = '' or lower(p.name) like lower(concat('%', :q, '%')))
              and (
                :filterColors = false
                or exists (
                    select v.id from ProductVariant v
                    where v.product = p
                      and v.isActive = true
                      and v.color.id in :colorIds
                )
              )
              and (
                :filterSizes = false
                or exists (
                    select v.id from ProductVariant v
                    where v.product = p
                      and v.isActive = true
                      and v.size.id in :sizeIds
                )
              )
                          AND (:minPrice IS NULL OR p.basePrice >= :minPrice)
                                AND (:maxPrice IS NULL OR p.basePrice <= :maxPrice)
            """)
    Page<Product> searchCards(
            @Param("q") String q,
            @Param("categoryId") Long categoryId,
            @Param("filterColors") boolean filterColors,
            @Param("colorIds") List<Integer> colorIds,
            @Param("filterSizes") boolean filterSizes,
            @Param("sizeIds") List<Integer> sizeIds,
            @Param("minPrice") BigDecimal minPrice,
            @Param("maxPrice") BigDecimal maxPrice,
            Pageable pageable
    );

    @Query("""
            select p from Product p
            where p.isActive = true
              and p.category.isActive = true
              and p.createdAt >= :createdFrom
              and p.createdAt <= :createdTo
            """)
    Page<Product> findNewArrivals(
            @Param("createdFrom") Instant createdFrom,
            @Param("createdTo") Instant createdTo,
            Pageable pageable
    );

    @Query("""
        select p from Product p
        where p.isActive = true
          and p.category.isActive = true
          and p.category.id = :categoryId
          and p.id <> :productId
          and p.basePrice between :minPrice and :maxPrice
          and exists (
              select v.id from ProductVariant v
              where v.product = p
                and v.isActive = true
                and v.stockQuantity > v.reservedQuantity
          )
        order by abs(p.basePrice - :basePrice) asc, p.id desc
        """)
    Page<Product> getProductsSimilar(
            @Param("categoryId") Long categoryId,
            @Param("productId") Long productId,
            @Param("basePrice") BigDecimal basePrice,
            @Param("minPrice") BigDecimal minPrice,
            @Param("maxPrice") BigDecimal maxPrice,
            Pageable pageable
    );

    @Query("""
            select p from Product p
            left join fetch p.category
            left join fetch p.sizeGuide
            where p.slug = :slug
              and p.isActive = true
            """)
    Optional<Product> findBySlugWithDetails(@Param("slug") String slug);
}
