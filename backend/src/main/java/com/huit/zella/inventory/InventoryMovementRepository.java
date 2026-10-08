package com.huit.zella.inventory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface InventoryMovementRepository extends JpaRepository<InventoryMovement, Long> {
    Optional<InventoryMovement> findFirstByVariantIdOrderByIdDesc(Long variantId);

    Page<InventoryMovement> findByVariantId(Long variantId, Pageable pageable);
}
