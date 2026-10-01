package com.huit.zella.variantimage;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VariantImageRepository extends JpaRepository<VariantImage, Long> {
    List<VariantImage> findByVariantIdOrderByDisplayOrderAscIdAsc(Long variantId);

    Optional<VariantImage> findByVariantIdAndIsPrimaryTrue(Long variantId);
}
