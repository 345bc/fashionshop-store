package com.huit.zella.color;

import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;

import org.springframework.data.jpa.repository.JpaRepository;

public interface ColorRepository extends JpaRepository<Color, Integer> {
    boolean existsByCodeIgnoreCase(String code);

    boolean existsByCodeIgnoreCaseAndIdNot(String code, Integer id);

    @Query("""
            select c from Color c
                where :query = '' or lower(c.name) like lower(concat('%', :query, '%'))
                    or lower(c.code) like lower(concat('%', :query, '%'))
                    or lower(c.hexCode) like lower(concat('%', :query, '%'))
            """)
    Page<Color> search(@Param("query") String query, Pageable pageable);
}
