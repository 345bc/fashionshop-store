package com.huit.zella.inventory;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
public interface InventoryMovementRepository extends JpaRepository<InventoryMovement, Long> {
    List<InventoryMovement> findByVariantIdOrderByIdDesc(Long variantId);
    Optional<InventoryMovement> findFirstByVariantIdOrderByIdDesc(Long variantId);
}
