package com.huit.zella.category;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {
    Optional<Category> findByIdAndIsActiveTrue(Long id);

    @EntityGraph(attributePaths = "parent")
    List<Category> findAllByParentIsNotNull();
}
