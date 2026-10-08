package com.huit.zella.customer;

import org.springframework.data.repository.query.Param;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CustomerRepository extends JpaRepository<Customer, Long> {
    Optional<Customer> findByUserId(Long userId);

    @Query("""
            select c from Customer c left join c.user u
                where (:tier is null or c.membershipTier = :tier)
                and (:query = '' or lower(c.fullName) like lower(concat('%', :query, '%'))
                    or lower(c.phone) like lower(concat('%', :query, '%'))
                    or lower(u.email) like lower(concat('%', :query, '%'))
                    or lower(u.userName) like lower(concat('%', :query, '%')))
            """)
    Page<Customer> search(@Param("query") String query, @Param("tier") String tier, Pageable pageable);
}
