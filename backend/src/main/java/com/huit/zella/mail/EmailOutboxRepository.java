package com.huit.zella.mail;

import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.Pageable;
import jakarta.persistence.LockModeType;

import java.time.Instant;
import java.util.*;

public interface EmailOutboxRepository extends JpaRepository<QueuedEmail, Long> {
    @Query("select e.id from QueuedEmail e where e.nextAttemptAt <= :now and e.attempts < 8 order by e.id")
    List<Long> pending(@Param("now") Instant now, Pageable pageable);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from QueuedEmail e where e.id = :id")
    Optional<QueuedEmail> lock(@Param("id") Long id);
}
