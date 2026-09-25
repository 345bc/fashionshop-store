package com.huit.zella.supplier;

import jakarta.persistence.Column;
import org.hibernate.annotations.Nationalized;

import java.time.Instant;

public record SupplierRespone(
        Long id,
        String name,
        String contactEmail,
        String phone,
        String address,
        String code,
        String contactPerson,
        Boolean isActive,
        Instant createdAt,
        Instant updatedAt
) {
    public static SupplierRespone from(Supplier supplier) {
        return new SupplierRespone(supplier.getId(),supplier.getName(),supplier.getContactEmail(),supplier.getPhone(),supplier.getAddress(),supplier.getCode(),supplier.getContactPerson(),supplier.getIsActive(),supplier.getCreatedAt(),supplier.getUpdatedAt());
    }

}
