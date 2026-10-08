package com.huit.zella.productimage;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ProductImageRepository extends JpaRepository<ProductImage, Long> {
    List<ProductImage> findByProductIdOrderByDisplayOrderAscIdAsc(Long productId);

    Optional<ProductImage> findByProductIdAndIsPrimaryTrue(Long productId);

    List<ProductImage>
    findByProductIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(
            List<Long> productIds
    );
}
