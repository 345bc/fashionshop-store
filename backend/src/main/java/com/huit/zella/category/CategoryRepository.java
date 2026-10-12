package com.huit.zella.category;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select category from Category category where category.id = :id")
    Optional<Category> findByIdForImageUpdate(@Param("id") Long id);
    Optional<Category> findByIdAndIsActiveTrue(Long id);

    boolean existsBySlugIgnoreCase(String slug);

    boolean existsBySlugIgnoreCaseAndIdNot(String slug, Long id);

    boolean existsByParentId(Long parentId);

    List<Category> findByParentIsNull(Sort sort);

    @EntityGraph(attributePaths = "parent")
    List<Category> findByParentId(Long parentId, Sort sort);

    @EntityGraph(attributePaths = "parent")
    @Query("""
            select c from Category c
            where c.parent is not null
              and (:active is null or c.isActive = :active)
              and (:query = '' or lower(c.name) like lower(concat('%', :query, '%'))
                  or lower(c.slug) like lower(concat('%', :query, '%')))
            """)
    Page<Category> search(@Param("query") String query, @Param("active") Boolean active, Pageable pageable);
}
