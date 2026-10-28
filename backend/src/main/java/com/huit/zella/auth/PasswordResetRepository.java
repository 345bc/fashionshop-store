package com.huit.zella.auth;

import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface PasswordResetRepository extends JpaRepository<PasswordReset, Long> {
    @Query("select r.userId from PasswordReset r where r.tokenHash = :hash")
    Optional<Long> findUserId(@Param("hash") String hash);
}
