package com.huit.zella.promotion;
import java.time.Instant;
import java.util.*;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
public interface PromotionRepository extends JpaRepository<Promotion,Long> {
    @Query("select distinct p from Promotion p left join fetch p.products where p.active=true and p.startsAt<=:now and p.endsAt>:now order by p.id")
    List<Promotion> effective(@Param("now") Instant now);
    @EntityGraph(attributePaths="products") List<Promotion> findAllByOrderByIdDesc();
    @Lock(LockModeType.PESSIMISTIC_WRITE) @Query("select p from Promotion p where p.id=:id") Optional<Promotion> lock(@Param("id") Long id);
}
