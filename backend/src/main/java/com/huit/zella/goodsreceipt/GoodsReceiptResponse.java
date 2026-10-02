package com.huit.zella.goodsreceipt;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
public record GoodsReceiptResponse(Long id, String code, Long supplierId, String supplierName,
    String status, String paymentStatus, BigDecimal totalAmount, BigDecimal paidAmount, BigDecimal remainingAmount,
    String note, Instant createdAt, Instant postedAt, Instant cancelledAt, String createdBy, String postedBy,
    List<Item> items, List<Payment> payments, BigDecimal returnedAmount, BigDecimal supplierRefundedAmount,
    BigDecimal supplierRefundDue, List<Returned> returns, List<Refund> refunds) {
    public record Item(Long variantId, String sku, String productName, String sizeName, String colorName,
        Integer quantity, BigDecimal unitCost, BigDecimal subtotal, int returnedQuantity) {}
    public record Payment(Long id, BigDecimal amount, String paymentMethod, String note, Instant paidAt, String createdBy) {}
    public record Returned(String code, String reason, BigDecimal amount, String createdBy, Instant createdAt, List<ReturnedItem> items) {}
    public record ReturnedItem(Long variantId, int quantity, BigDecimal unitCost) {}
    public record Refund(BigDecimal amount, String paymentMethod, String note, String createdBy, Instant createdAt) {}
    public static GoodsReceiptResponse from(GoodsReceipt r) {
        BigDecimal paid = r.getPayments().stream().map(SupplierPayment::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal balance = r.getTotalAmount().subtract(r.getReturnedAmount()).subtract(paid);
        return new GoodsReceiptResponse(r.getId(), r.getCode(), r.getSupplier().getId(), r.getSupplier().getName(),
            r.getStatus(), r.getPaymentStatus(), r.getTotalAmount(), paid, balance.max(BigDecimal.ZERO),
            r.getNote(), r.getCreatedAt(), r.getPostedAt(), r.getCancelledAt(),
            r.getCreatedBy() == null ? null : r.getCreatedBy().getUserName(),
            r.getPostedBy() == null ? null : r.getPostedBy().getUserName(),
            r.getItems().stream().map(i -> new Item(i.getVariant().getId(), i.getSkuSnapshot(),
                i.getProductNameSnapshot(), i.getSizeNameSnapshot(), i.getColorNameSnapshot(),
                i.getQuantity(), i.getUnitCost(), i.getUnitCost().multiply(BigDecimal.valueOf(i.getQuantity())),
                r.getReturns().stream().flatMap(d -> d.getItems().stream()).filter(t -> t.getVariant().getId().equals(i.getVariant().getId()))
                    .mapToInt(SupplierReturnItem::getQuantity).sum())).toList(),
            r.getPayments().stream().map(p -> new Payment(p.getId(), p.getAmount(), p.getPaymentMethod(), p.getNote(),
                p.getPaidAt(), p.getCreatedBy() == null ? null : p.getCreatedBy().getUserName())).toList(),
            r.getReturnedAmount(), r.getSupplierRefundedAmount(), balance.negate().subtract(r.getSupplierRefundedAmount()).max(BigDecimal.ZERO),
            r.getReturns().stream().map(d -> new Returned(d.getCode(), d.getReason(), d.getAmount(), d.getCreatedBy().getUserName(), d.getCreatedAt(),
                d.getItems().stream().map(i -> new ReturnedItem(i.getVariant().getId(), i.getQuantity(), i.getUnitCost())).toList())).toList(),
            r.getRefunds().stream().map(f -> new Refund(f.getAmount(), f.getPaymentMethod(), f.getNote(), f.getCreatedBy().getUserName(), f.getCreatedAt())).toList());
    }
}
