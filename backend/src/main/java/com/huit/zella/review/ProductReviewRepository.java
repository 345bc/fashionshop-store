package com.huit.zella.review;

import java.util.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

public interface ProductReviewRepository extends JpaRepository<ProductReview, Long> {
    @Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from ProductReview r where r.id = :id")
    Optional<ProductReview> findForUpdate(@Param("id") Long id);
    Optional<ProductReview> findByOrderItemId(Long id);
    List<ProductReview> findByOrderIdIn(List<Long> ids);
    Page<ProductReview> findByProductIdAndHiddenFalse(Long productId, Pageable pageable);
    long countByProductIdAndHiddenFalse(Long productId);
    @Query("select avg(r.rating) from ProductReview r where r.product.id = :id and r.hidden = false")
    Double average(@Param("id") Long productId);

    @Query("select r.product.id, avg(r.rating), count(r) from ProductReview r where r.product.id in :productIds and r.hidden = false group by r.product.id")
    List<Object[]> getStatsByProductIds(@Param("productIds") List<Long> productIds);
}
