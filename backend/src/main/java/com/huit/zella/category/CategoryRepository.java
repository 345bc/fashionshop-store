package com.huit.zella.category;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Sort;

import java.util.List;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    Optional<Category> findByIdAndIsActiveTrue(Long id);

    boolean existsBySlugIgnoreCase(String slug);

    boolean existsBySlugIgnoreCaseAndIdNot(String slug, Long id);

    boolean existsByParentId(Long parentId);

    @EntityGraph(attributePaths = "parent")
    List<Category> findByParentIsNotNull(Sort sort);

    List<Category> findByParentIsNull(Sort sort);

    @EntityGraph(attributePaths = "parent")
    List<Category> findAllByParentIsNotNull();
}
