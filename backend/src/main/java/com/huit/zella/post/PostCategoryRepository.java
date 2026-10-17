package com.huit.zella.post;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface PostCategoryRepository extends JpaRepository<PostCategory,Long> {
 List<PostCategory> findByActiveTrueOrderByNameAsc();
 boolean existsBySlugAndIdNot(String slug, Long id);
 boolean existsBySlug(String slug);
 boolean existsByIdAndActiveTrue(Long id);
}
