package com.huit.zella.post;

import org.springframework.data.jpa.repository.*;

import java.util.Optional;

public interface PostRepository extends JpaRepository<Post, Long>, JpaSpecificationExecutor<Post> {
    Optional<Post> findBySlug(String slug);

    boolean existsBySlugAndIdNot(String slug, Long id);

    boolean existsBySlug(String slug);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Post p where p.id=:id")
    Optional<Post> lockForView(Long id);

    @Modifying
    @Query("update Post p set p.viewCount=p.viewCount+1 where p.id=:id")
    int incrementViews(Long id);
}
