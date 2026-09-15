package com.huit.zella.auth;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    //    @EntityGraph: Chỉ định các quan hệ (relationship) cần load ngay cùng entity,
    //    giúp tránh phải query thêm khi truy cập quan hệ đó.
    //    EntityGraph = “Lấy entity này kèm những quan hệ mình chỉ định.”
    @EntityGraph(attributePaths = "roles")
    Optional<User> findByEmailIgnoreCase(String email);

//    @EntityGraph(attributePaths = "roles")
//    Optional<User> findByTenantIdAndExternalSubject(String tenantId, String externalSubject);
}
