package com.huit.zella.goodsreceipt;
import com.huit.zella.auth.UserRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.inventory.InventoryMovementRepository;
import com.huit.zella.inventory.InventoryService;
import com.huit.zella.productvariant.ProductVariantRepository;
import com.huit.zella.supplier.SupplierRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.*;

@Service @RequiredArgsConstructor
public class GoodsReceiptService {
    private final GoodsReceiptRepository receipts;
    private final SupplierRepository suppliers;
    private final ProductVariantRepository variants;
    private final UserRepository users;
    private final InventoryService inventory;
    private final InventoryMovementRepository movements;
    private static final BigDecimal MAX_AMOUNT = new BigDecimal("9999999999999999.99");

    @Transactional(readOnly = true)
    public List<GoodsReceiptResponse> list() {
        return receipts.findAll(Sort.by(Sort.Direction.DESC, "id")).stream().map(GoodsReceiptResponse::from).toList();
    }
    @Transactional(readOnly = true)
    public GoodsReceiptResponse get(Long id) {
        return GoodsReceiptResponse.from(receipts.findById(id).orElseThrow(() -> error("RECEIPT_NOT_FOUND", "Không tìm thấy phiếu nhập")));
    }
    @Transactional
    public GoodsReceiptResponse create(CreateGoodsReceiptRequest request, Long actorId) {
        var receipt = new GoodsReceipt();
        receipt.setCode("GR-" + UUID.randomUUID().toString().toUpperCase(Locale.ROOT));
        receipt.setCreatedBy(users.getReferenceById(actorId));
        apply(receipt, request);
        return GoodsReceiptResponse.from(receipts.save(receipt));
    }
    @Transactional
    public GoodsReceiptResponse update(Long id, CreateGoodsReceiptRequest request) {
        var receipt = lock(id);
        requireStatus(receipt, "DRAFT");
        apply(receipt, request);
        return GoodsReceiptResponse.from(receipts.save(receipt));
    }
    @Transactional
    public GoodsReceiptResponse post(Long id, Long actorId) {
        var receipt = lock(id);
        requireStatus(receipt, "DRAFT");
        if (!Boolean.TRUE.equals(receipt.getSupplier().getIsActive()))
            throw error("SUPPLIER_INACTIVE", "Nhà cung cấp đã ngừng hoạt động");
        if (receipt.getItems().isEmpty()) throw error("EMPTY_RECEIPT", "Phiếu nhập chưa có hàng");
        var actor = users.getReferenceById(actorId);
        for (var item : orderedItems(receipt)) {
            var variant = inventory.lockVariant(item.getVariant().getId());
            if (!variant.isActive() || !variant.getProduct().isActive()
                    || variant.getProduct().getSupplier() == null
                    || !receipt.getSupplier().getId().equals(variant.getProduct().getSupplier().getId()))
                throw error("INVALID_RECEIPT_VARIANT", "Biến thể đã ngừng hoạt động hoặc đổi nhà cung cấp");
            int before = variant.getStockQuantity();
            long after = (long) before + item.getQuantity();
            if (after > Integer.MAX_VALUE) throw error("STOCK_OVERFLOW", "Số lượng tồn vượt giới hạn");
            item.setBeforeUnitCost(variant.getCostPrice());
            BigDecimal value = variant.getCostPrice().multiply(BigDecimal.valueOf(before))
                .add(item.getUnitCost().multiply(BigDecimal.valueOf(item.getQuantity())));
            variant.setCostPrice(value.divide(BigDecimal.valueOf(after), 2, RoundingMode.HALF_UP));
            inventory.record(variant, (int) after, "RECEIPT", receipt.getCode(), receipt.getNote(), actor);
        }
        receipt.setStatus("POSTED"); receipt.setPostedAt(Instant.now()); receipt.setPostedBy(actor);
        receipt.setPaymentStatus(receipt.getTotalAmount().signum() == 0 ? "PAID" : "UNPAID");
        return GoodsReceiptResponse.from(receipt);
    }
    @Transactional
    public GoodsReceiptResponse cancel(Long id, Long actorId) {
        var receipt = lock(id);
        if ("CANCELLED".equals(receipt.getStatus())) throw error("RECEIPT_CANCELLED", "Phiếu đã bị hủy");
        if (!receipt.getPayments().isEmpty()) throw error("RECEIPT_HAS_PAYMENT", "Phiếu đã thanh toán không thể hủy");
        if (!receipt.getReturns().isEmpty()) throw error("RECEIPT_HAS_RETURN", "Phiếu có hàng trả nhà cung cấp không thể hủy");
        var actor = users.getReferenceById(actorId);
        if ("POSTED".equals(receipt.getStatus())) {
            for (var item : orderedItems(receipt)) {
                var variant = inventory.lockVariant(item.getVariant().getId());
                var latest = movements.findFirstByVariantIdOrderByIdDesc(variant.getId());
                if (item.getBeforeUnitCost() == null || latest.isEmpty()
                        || !"RECEIPT".equals(latest.get().getMovementType())
                        || !receipt.getCode().equals(latest.get().getReferenceCode()))
                    throw error("RECEIPT_HAS_LATER_MOVEMENT", "SKU đã có biến động tiếp theo. Không thể đảo phiếu nhập này");
                int after = variant.getStockQuantity() - item.getQuantity();
                if (after < variant.getReservedQuantity() || after < 0)
                    throw error("INSUFFICIENT_STOCK", "Không đủ tồn khả dụng để đảo phiếu nhập");
                inventory.record(variant, after, "RECEIPT_REVERSAL", receipt.getCode(), "Hủy phiếu nhập", actor);
                variant.setCostPrice(item.getBeforeUnitCost());
            }
        }
        receipt.setStatus("CANCELLED"); receipt.setCancelledAt(Instant.now()); receipt.setCancelledBy(actor);
        return GoodsReceiptResponse.from(receipt);
    }
    @Transactional
    public GoodsReceiptResponse pay(Long id, CreateSupplierPaymentRequest request, Long actorId) {
        var receipt = lock(id);
        requireStatus(receipt, "POSTED");
        BigDecimal paid = receipt.getPayments().stream().map(SupplierPayment::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal remaining = receipt.getTotalAmount().subtract(receipt.getReturnedAmount()).subtract(paid).max(BigDecimal.ZERO);
        if (request.amount().compareTo(remaining) > 0)
            throw error("PAYMENT_EXCEEDS_BALANCE", "Số tiền vượt công nợ còn lại");
        var payment = new SupplierPayment();
        payment.setReceipt(receipt); payment.setAmount(request.amount());
        payment.setPaymentMethod(request.paymentMethod()); payment.setNote(request.note());
        payment.setCreatedBy(users.getReferenceById(actorId));
        receipt.getPayments().add(payment);
        receipt.setPaymentStatus(request.amount().compareTo(remaining) == 0 ? "PAID" : "PARTIAL");
        receipts.saveAndFlush(receipt);
        return GoodsReceiptResponse.from(receipt);
    }
    @Transactional
    public GoodsReceiptResponse returnToSupplier(Long id, CreateSupplierReturnRequest request, Long actorId) {
        GoodsReceipt receipt = lock(id);
        requireStatus(receipt, "POSTED");
        SupplierReturn document = new SupplierReturn();
        document.setCode("SR-" + UUID.randomUUID().toString().toUpperCase(Locale.ROOT));
        document.setReceipt(receipt); document.setReason(request.reason().trim());
        document.setCreatedBy(users.getReferenceById(actorId));
        BigDecimal credit = BigDecimal.ZERO;
        Set<Long> ids = new HashSet<>();
        for (CreateSupplierReturnRequest.Item line : request.items().stream()
                .sorted(Comparator.comparing(CreateSupplierReturnRequest.Item::variantId)).toList()) {
            if (!ids.add(line.variantId())) throw error("DUPLICATE_VARIANT", "SKU bị trùng trong phiếu trả");
            GoodsReceiptItem received = receipt.getItems().stream().filter(i -> i.getVariant().getId().equals(line.variantId()))
                .findFirst().orElseThrow(() -> error("INVALID_RETURN_VARIANT", "SKU không thuộc phiếu nhập"));
            int returned = receipt.getReturns().stream().flatMap(r -> r.getItems().stream())
                .filter(i -> i.getVariant().getId().equals(line.variantId())).mapToInt(SupplierReturnItem::getQuantity).sum();
            if ((long) returned + line.quantity() > received.getQuantity())
                throw error("RETURN_EXCEEDS_RECEIVED", "Số trả vượt số đã nhập còn lại của phiếu");
            com.huit.zella.productvariant.ProductVariant variant = inventory.lockVariant(line.variantId());
            if (variant.getStockQuantity() - variant.getReservedQuantity() < line.quantity())
                throw error("INSUFFICIENT_STOCK", "Không đủ tồn khả dụng để trả nhà cung cấp");
            SupplierReturnItem item = new SupplierReturnItem();
            item.setDocument(document); item.setVariant(variant); item.setQuantity(line.quantity()); item.setUnitCost(received.getUnitCost());
            document.getItems().add(item);
            credit = credit.add(received.getUnitCost().multiply(BigDecimal.valueOf(line.quantity())));
            // Remove at current moving-average inventory valuation; supplier credit uses the original invoice unit cost.
            inventory.record(variant, variant.getStockQuantity() - line.quantity(), "SUPPLIER_RETURN",
                document.getCode(), document.getReason(), document.getCreatedBy());
        }
        document.setAmount(credit);
        receipt.getReturns().add(document);
        receipt.setReturnedAmount(receipt.getReturnedAmount().add(credit));
        BigDecimal paid = receipt.getPayments().stream().map(SupplierPayment::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal net = receipt.getTotalAmount().subtract(receipt.getReturnedAmount());
        receipt.setPaymentStatus(paid.compareTo(net) >= 0 ? "PAID" : paid.signum() == 0 ? "UNPAID" : "PARTIAL");
        receipts.saveAndFlush(receipt);
        return GoodsReceiptResponse.from(receipt);
    }

    @Transactional
    public GoodsReceiptResponse supplierRefund(Long id, CreateSupplierPaymentRequest request, Long actorId) {
        GoodsReceipt receipt = lock(id);
        requireStatus(receipt, "POSTED");
        BigDecimal paid = receipt.getPayments().stream().map(SupplierPayment::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal due = paid.subtract(receipt.getTotalAmount().subtract(receipt.getReturnedAmount()))
            .subtract(receipt.getSupplierRefundedAmount()).max(BigDecimal.ZERO);
        if (request.amount().compareTo(due) > 0)
            throw error("REFUND_EXCEEDS_BALANCE", "Số tiền nhận hoàn vượt khoản nhà cung cấp phải hoàn");
        SupplierRefund refund = new SupplierRefund();
        refund.setReceipt(receipt); refund.setAmount(request.amount()); refund.setPaymentMethod(request.paymentMethod());
        refund.setNote(request.note()); refund.setCreatedBy(users.getReferenceById(actorId));
        receipt.getRefunds().add(refund);
        receipt.setSupplierRefundedAmount(receipt.getSupplierRefundedAmount().add(request.amount()));
        receipts.saveAndFlush(receipt);
        return GoodsReceiptResponse.from(receipt);
    }
    private void apply(GoodsReceipt receipt, CreateGoodsReceiptRequest request) {
        var supplier = suppliers.findByIdAndIsActiveTrue(request.supplierId())
            .orElseThrow(() -> error("SUPPLIER_NOT_FOUND", "Không tìm thấy nhà cung cấp đang hoạt động"));
        Map<Long, GoodsReceiptItem> lines = new LinkedHashMap<>();
        for (var line : request.items()) {
            var variant = variants.findById(line.variantId()).orElseThrow(() -> error("VARIANT_NOT_FOUND", "Không tìm thấy biến thể"));
            if (!variant.isActive() || !variant.getProduct().isActive()
                    || variant.getProduct().getSupplier() == null
                    || !supplier.getId().equals(variant.getProduct().getSupplier().getId()))
                throw error("INVALID_RECEIPT_VARIANT", "Biến thể không thuộc nhà cung cấp hoặc đã ngừng hoạt động");
            var existing = lines.get(line.variantId());
            if (existing != null) {
                if (existing.getUnitCost().compareTo(line.unitCost()) != 0)
                    throw error("DUPLICATE_VARIANT_COST", "SKU trùng phải có cùng đơn giá nhập");
                long qty = (long) existing.getQuantity() + line.quantity();
                if (qty > Integer.MAX_VALUE) throw error("STOCK_OVERFLOW", "Số lượng vượt giới hạn");
                existing.setQuantity((int) qty);
            } else {
                var item = new GoodsReceiptItem();
                item.setReceipt(receipt); item.setVariant(variant);
                item.setQuantity(line.quantity()); item.setUnitCost(line.unitCost());
                item.setSkuSnapshot(variant.getSku()); item.setProductNameSnapshot(variant.getProduct().getName());
                item.setSizeNameSnapshot(variant.getSize().getName()); item.setColorNameSnapshot(variant.getColor().getName());
                lines.put(line.variantId(), item);
            }
        }
        BigDecimal total = lines.values().stream().map(i -> i.getUnitCost().multiply(BigDecimal.valueOf(i.getQuantity())))
            .reduce(BigDecimal.ZERO, BigDecimal::add);
        if (total.compareTo(MAX_AMOUNT) > 0) throw error("AMOUNT_OVERFLOW", "Tổng tiền vượt giới hạn");
        receipt.setSupplier(supplier); receipt.setNote(request.note()); receipt.setTotalAmount(total);
        receipt.getItems().clear(); receipt.getItems().addAll(lines.values());
    }
    private List<GoodsReceiptItem> orderedItems(GoodsReceipt r) {
        return r.getItems().stream().sorted(Comparator.comparing(i -> i.getVariant().getId())).toList();
    }
    private GoodsReceipt lock(Long id) {
        return receipts.findByIdForUpdate(id).orElseThrow(() -> error("RECEIPT_NOT_FOUND", "Không tìm thấy phiếu nhập"));
    }
    private void requireStatus(GoodsReceipt r, String status) {
        if (!status.equals(r.getStatus())) throw error("INVALID_RECEIPT_STATUS", "Trạng thái phiếu không cho phép thao tác này");
    }
    private BusinessException error(String code, String message) {
        return new BusinessException(HttpStatus.CONFLICT, code, message);
    }
}
