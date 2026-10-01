package com.huit.zella.sizeguide;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SizeGuideRepository extends JpaRepository<SizeGuide, Long> {
    Optional<SizeGuide> findByIdAndIsActiveTrue(Long id);
}
