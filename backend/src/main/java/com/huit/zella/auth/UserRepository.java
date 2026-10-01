package com.huit.zella.auth;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    //    @EntityGraph: Chỉ định các quan hệ (relationship) cần load ngay cùng entity,
    //    giúp tránh phải query thêm khi truy cập quan hệ đó.
    //    EntityGraph = “Lấy entity này kèm những quan hệ mình chỉ định.”
    @EntityGraph(attributePaths = "roles")
    Optional<User> findByEmailIgnoreCase(String email);

    @EntityGraph(attributePaths = "roles")
    Optional<User> findByUserNameIgnoreCase(String userName);

    @Query("SELECT DISTINCT u FROM User u LEFT JOIN u.roles r WHERE " +
           "(:query IS NULL OR LOWER(u.userName) LIKE LOWER(CONCAT('%', :query, '%'))) AND " +
           "(:role IS NULL OR r.roleCode = :role)")
    Page<User> searchUsers(@org.springframework.data.repository.query.Param("query") String query, 
                           @org.springframework.data.repository.query.Param("role") String role, 
                           Pageable pageable);

    boolean existsByUserNameIgnoreCaseAndIdNot(String username, Long id);

    boolean existsByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCaseAndIdNot(String email, Long id);

//    @EntityGraph(attributePaths = "roles")
//    Optional<User> findByTenantIdAndExternalSubject(String tenantId, String externalSubject);
}
