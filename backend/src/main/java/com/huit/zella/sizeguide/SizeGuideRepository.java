package com.huit.zella.sizeguide;

import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SizeGuideRepository extends JpaRepository<SizeGuide, Long> {
    Optional<SizeGuide> findByIdAndIsActiveTrue(Long id);

    @Query("""
            select s from SizeGuide s
                where (:active is null or s.isActive = :active)
                and (:query = '' or lower(s.name) like lower(concat('%', :query, '%'))
                    or lower(s.description) like lower(concat('%', :query, '%')))
            """)
    Page<SizeGuide> search(@Param("query") String query, @Param("active") Boolean active, Pageable pageable);
}
