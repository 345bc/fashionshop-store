package com.huit.zella.staff;

import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import org.springframework.data.domain.*;

public interface StaffRepository extends JpaRepository<Staff, Long> {
    boolean existsByUserId(Long id);

    java.util.Optional<Staff> findByUserId(Long id);

    @Query("select s from Staff s join s.user u where (:q is null or lower(s.fullName) like lower(concat('%',:q,'%')) or lower(u.email) like lower(concat('%',:q,'%'))) and (:active is null or u.isActive=:active)")
    Page<Staff> search(@Param("q") String q, @Param("active") Boolean active, Pageable pageable);
}
