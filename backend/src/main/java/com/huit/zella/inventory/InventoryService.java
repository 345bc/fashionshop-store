package com.huit.zella.inventory;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import com.huit.zella.auth.User;
import com.huit.zella.auth.UserRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.productvariant.ProductVariantRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;

@Service @RequiredArgsConstructor
public class InventoryService {
    private final ProductVariantRepository variants;
    private final InventoryMovementRepository movements;
    private final InventoryAdjustmentRepository adjustments;
    private final UserRepository users;

    @Transactional(readOnly = true)
    public Page<InventoryResponse> list(String query, Long supplierId, String status, Pageable pageable) {
        String q = query == null ? "" : query.trim();
        String filter = status == null || "all".equals(status) ? null : status;
        Page<ProductVariant> page = variants.searchInventory(q, supplierId, filter, pageable);
        return page.map(InventoryResponse::from);
    }

    @Transactional(readOnly = true)
    public Page<InventoryMovementResponse> history(Long variantId, Pageable pageable) {
        if (!variants.existsById(variantId)) throw error("VARIANT_NOT_FOUND", "Không tìm thấy biến thể");
        return movements.findByVariantId(variantId, pageable).map(InventoryMovementResponse::from);
    }

    @Transactional
    public String adjust(CreateInventoryAdjustmentRequest request, Long actorId) {
        var document = new InventoryAdjustment();
        document.setCode("ADJ-" + UUID.randomUUID().toString().toUpperCase(Locale.ROOT));
        document.setReason(request.reason().trim());
        User actor = users.getReferenceById(actorId);
        document.setCreatedBy(actor);
        Set<Long> ids = new HashSet<>();
        for (var line : request.items().stream().sorted(Comparator.comparing(CreateInventoryAdjustmentRequest.Item::variantId)).toList()) {
            if (!ids.add(line.variantId())) throw error("DUPLICATE_VARIANT", "Biến thể bị trùng trong phiếu kiểm kê");
            ProductVariant variant = lockVariant(line.variantId());
            if (!variant.getStockQuantity().equals(line.expectedQuantity()))
                throw error("STALE_INVENTORY", "Tồn kho đã thay đổi. Vui lòng tải lại trước khi điều chỉnh");
            if (line.countedQuantity() < variant.getReservedQuantity())
                throw error("RESERVED_STOCK", "Tồn thực tế không được nhỏ hơn số đã giữ");
            var item = new InventoryAdjustmentItem();
            item.setAdjustment(document); item.setVariant(variant);
            item.setBeforeQuantity(variant.getStockQuantity()); item.setCountedQuantity(line.countedQuantity());
            document.getItems().add(item);
        }
        adjustments.save(document);
        for (var item : document.getItems()) {
            if (!item.getBeforeQuantity().equals(item.getCountedQuantity())) {
                record(item.getVariant(), item.getCountedQuantity(), "ADJUSTMENT", document.getCode(), document.getReason(), actor);
            }
        }
        return document.getCode();
    }

    public ProductVariant lockVariant(Long id) {
        return variants.findByIdForInventoryUpdate(id).orElseThrow(() -> error("VARIANT_NOT_FOUND", "Không tìm thấy biến thể"));
    }

    public void record(ProductVariant variant, int after, String type, String reference, String reason, User actor) {
        changeStockAndReservation(variant, after, variant.getReservedQuantity(), type, reference, reason, actor);
    }

    public void changeStockAndReservation(ProductVariant variant, int after, int reserved,
            String type, String reference, String reason, User actor) {
        if (after < 0 || reserved < 0 || reserved > after)
            throw error("INVALID_INVENTORY", "Tồn kho hoặc số đã giữ không hợp lệ");
        int before = variant.getStockQuantity();
        var movement = new InventoryMovement();
        movement.setVariant(variant); movement.setMovementType(type);
        movement.setQuantityChange(after - before); movement.setBeforeQuantity(before); movement.setAfterQuantity(after);
        movement.setBeforeReserved(variant.getReservedQuantity()); movement.setAfterReserved(reserved);
        movement.setReferenceCode(reference); movement.setReason(reason); movement.setCreatedBy(actor);
        variant.setStockQuantity(after);
        variant.setReservedQuantity(reserved);
        movements.save(movement);
    }

    private BusinessException error(String code, String message) {
        return new BusinessException(HttpStatus.CONFLICT, code, message);
    }
}
