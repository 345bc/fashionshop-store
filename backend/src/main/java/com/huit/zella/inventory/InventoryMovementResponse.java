package com.huit.zella.inventory;
import java.time.Instant;
public record InventoryMovementResponse(Long id, String movementType, Integer quantityChange,
    Integer beforeQuantity, Integer afterQuantity, String referenceCode, String reason, Instant createdAt, String createdBy,
    Integer beforeReserved, Integer afterReserved) {
    public static InventoryMovementResponse from(InventoryMovement m) {
        return new InventoryMovementResponse(m.getId(), m.getMovementType(), m.getQuantityChange(), m.getBeforeQuantity(),
            m.getAfterQuantity(), m.getReferenceCode(), m.getReason(), m.getCreatedAt(),
            m.getCreatedBy() == null ? null : m.getCreatedBy().getUserName(), m.getBeforeReserved(), m.getAfterReserved());
    }
}
