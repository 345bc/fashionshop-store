package com.huit.zella.orderreturn;

import com.huit.zella.auth.User;
import com.huit.zella.auth.UserRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.inventory.InventoryService;
import com.huit.zella.order.*;
import com.huit.zella.productvariant.ProductVariant;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.time.Clock;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ReturnService {
    private final ReturnRepository returnRepository;
    private final OrderRepository orderRepository;
    private final OrderService orderService;
    private final UserRepository userRepository;
    private final InventoryService inventoryService;
    private final com.huit.zella.loyalty.LoyaltyService loyalty;
    private final Clock orderClock;

    @Transactional(readOnly = true)
    public org.springframework.data.domain.Page<ReturnOrderSummaryResponse> management(String query, String status,
            org.springframework.data.domain.Pageable pageable) {
        ReturnStatus filter = null;
        if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) {
            try { filter = ReturnStatus.valueOf(status.trim().toUpperCase(Locale.ROOT)); }
            catch (IllegalArgumentException exception) { throw error("INVALID_RETURN_STATUS", "Trạng thái hoàn hàng không hợp lệ"); }
        }
        var page = orderRepository.searchReturnOrders(query == null ? "" : query.trim(), filter, pageable);
        if (page.isEmpty()) return page.map(order -> null);
        var requests = returnRepository.findByOrderIdInOrderByIdDesc(page.getContent().stream().map(Order::getId).toList())
                .stream().collect(java.util.stream.Collectors.groupingBy(r -> r.getOrder().getId()));
        return page.map(order -> ReturnOrderSummaryResponse.from(order, requests.get(order.getId())));
    }

    @Transactional(readOnly = true)
    public List<ReturnResponse> list(Long orderId) {
        return returnRepository.findByOrderIdOrderByIdDesc(orderId).stream().map(ReturnResponse::from).toList();
    }

    @Transactional
    public ReturnResponse create(CreateReturnRequest request, Long actorId) {
        Order order = orderService.lock(request.orderId());
        if (order.getStatus() != OrderStatus.SHIPPED && order.getStatus() != OrderStatus.DELIVERED)
            throw error("ORDER_NOT_SHIPPED", "Chỉ lập phiếu trả cho đơn đã xuất kho");
        if (order.getStatus() == OrderStatus.DELIVERED) {
            var deliveredAt = order.getHistories().stream()
                .filter(h -> "DELIVERED".equals(h.getNewStatus()))
                .map(OrderHistory::getCreatedAt).filter(Objects::nonNull)
                .min(Comparator.naturalOrder())
                .orElseThrow(() -> error("DELIVERY_DATE_MISSING", "Thiếu thời điểm giao thành công, cần đối soát trước khi trả hàng"));
            var now = LocalDateTime.now(orderClock);
            if (deliveredAt.isAfter(now)) throw error("INVALID_DELIVERY_DATE", "Thời điểm giao hàng không hợp lệ");
            if (deliveredAt.plusDays(14).isBefore(now))
                throw error("RETURN_EXPIRED", "Đã quá 14 ngày kể từ khi nhận hàng, không thể yêu cầu trả hàng");
        }
        ReturnRequest document = new ReturnRequest();
        document.setCreatedAt(LocalDateTime.now(orderClock)); document.setUpdatedAt(document.getCreatedAt());
        document.setCode("RET-" + UUID.randomUUID().toString().replace("-", "").substring(0, 28).toUpperCase(Locale.ROOT));
        document.setOrder(order); document.setCustomer(order.getCustomer()); document.setNote(request.reason().trim());
        Set<Long> ids = new HashSet<>();
        for (CreateReturnRequest.Item line : request.items()) {
            if (!ids.add(line.orderItemId())) throw error("DUPLICATE_ITEM", "Dòng đơn hàng bị trùng");
            OrderItem sold = order.getItems().stream().filter(i -> i.getId().equals(line.orderItemId())).findFirst()
                .orElseThrow(() -> error("INVALID_RETURN_ITEM", "Dòng hàng không thuộc đơn"));
            long committed = returnRepository.committedQuantity(sold.getId());
            if (committed + line.quantity() > sold.getQuantity())
                throw error("RETURN_EXCEEDS_SOLD", "Số trả vượt số đã mua hoặc đã có phiếu trả đang xử lý");
            ReturnItem item = new ReturnItem();
            item.setRequest(document); item.setOrderItem(sold); item.setQuantity(line.quantity()); item.setUnitCost(sold.getUnitCost());
            document.getItems().add(item);
        }
        if (order.getStatus() == OrderStatus.SHIPPED
                && (document.getItems().size() != order.getItems().size()
                    || document.getItems().stream().anyMatch(i -> !i.getQuantity().equals(i.getOrderItem().getQuantity()))))
            throw error("FULL_SHIPMENT_RETURN_REQUIRED", "Đơn chưa giao thành công phải nhận lại toàn bộ kiện hàng");
        addHistory(document, null, ReturnStatus.PENDING, document.getNote(), actorId);
        return ReturnResponse.from(returnRepository.saveAndFlush(document));
    }

    @Transactional
    public ReturnResponse approve(Long id, Long actorId) {
        ReturnRequest document = lock(id);
        requireStatus(document, ReturnStatus.PENDING);
        transition(document, ReturnStatus.APPROVED, "Duyệt nhận hàng trả", actorId);
        document.setApprovedAt(LocalDateTime.now(orderClock));
        return ReturnResponse.from(document);
    }

    @Transactional
    public ReturnResponse reject(Long id, String note, Long actorId) {
        ReturnRequest document = lock(id);
        requireStatus(document, ReturnStatus.PENDING);
        transition(document, ReturnStatus.REJECTED, note, actorId);
        document.setRejectedAt(LocalDateTime.now(orderClock));
        return ReturnResponse.from(document);
    }

    @Transactional
    public ReturnResponse cancel(Long id, String note, Long actorId) {
        ReturnRequest document = lock(id);
        if (document.getStatus() != ReturnStatus.PENDING && document.getStatus() != ReturnStatus.APPROVED)
            throw error("INVALID_RETURN_STATUS", "Chỉ hủy phiếu chưa nhận hàng");
        transition(document, ReturnStatus.CANCELLED, note, actorId);
        document.setCancelledAt(LocalDateTime.now(orderClock));
        return ReturnResponse.from(document);
    }

    @Transactional
    public ReturnResponse receive(Long id, ReceiveReturnRequest request, Long actorId) {
        ReturnRequest document = lock(id);
        requireStatus(document, ReturnStatus.APPROVED);
        Map<Long, String> conditions = new HashMap<>();
        for (ReceiveReturnRequest.Item item : request.items())
            if (conditions.put(item.returnItemId(), item.condition()) != null)
                throw error("DUPLICATE_ITEM", "Dòng kiểm tra bị trùng");
        if (conditions.size() != document.getItems().size()
                || document.getItems().stream().anyMatch(i -> !conditions.containsKey(i.getId())))
            throw error("INVALID_RETURN_ITEM", "Phải kiểm tra đủ và đúng các dòng hàng trả");
        User actor = userRepository.getReferenceById(actorId);
        BigDecimal refund = BigDecimal.ZERO;
        for (ReturnItem item : document.getItems().stream()
                .sorted(Comparator.comparing(i -> i.getOrderItem().getVariant().getId())).toList()) {
            item.setItemCondition(conditions.get(item.getId()));
            if ("INTACT".equals(item.getItemCondition())) {
                ProductVariant variant = inventoryService.lockVariant(item.getOrderItem().getVariant().getId());
                long after = (long) variant.getStockQuantity() + item.getQuantity();
                if (after > Integer.MAX_VALUE) throw error("STOCK_OVERFLOW", "Tồn vượt giới hạn");
                BigDecimal value = variant.getCostPrice().multiply(BigDecimal.valueOf(variant.getStockQuantity()))
                    .add(item.getUnitCost().multiply(BigDecimal.valueOf(item.getQuantity())));
                variant.setCostPrice(value.divide(BigDecimal.valueOf(after), 2, RoundingMode.HALF_UP));
                inventoryService.record(variant, (int) after, "CUSTOMER_RETURN", document.getCode(), document.getNote(), actor);
            } else {
                // Damaged goods were received but are not available for sale; retain an audit movement with zero stock delta.
                ProductVariant variant = inventoryService.lockVariant(item.getOrderItem().getVariant().getId());
                inventoryService.record(variant, variant.getStockQuantity(), "RETURN_DAMAGED", document.getCode(),
                    "Hàng trả hỏng, không nhập tồn bán", actor);
            }
            refund = refund.add(item.getOrderItem().getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity())));
        }
        // Failed delivery returns the full parcel and refunds shipping too; delivered merchandise returns exclude shipping.
        if (document.getOrder().getStatus() == OrderStatus.SHIPPED) refund = document.getOrder().getTotalAmount();
        else if(document.getOrder().getDiscountAmount().signum()>0) {
            Order sold=document.getOrder();
            BigDecimal net=sold.getSubtotal().subtract(sold.getDiscountAmount());
            // The last return absorbs rounding so the cumulative merchandise refund equals the amount paid.
            refund=returnRepository.receivedValue(sold.getId()).add(refund).compareTo(sold.getSubtotal())>=0
                    ? net.subtract(returnRepository.receivedRefund(sold.getId())).max(BigDecimal.ZERO)
                    : refund.multiply(net).divide(sold.getSubtotal(),0,RoundingMode.DOWN);
        }
        document.setRefundAmount("PAID".equals(document.getOrder().getPaymentStatus()) ? refund : BigDecimal.ZERO);
        transition(document, ReturnStatus.RECEIVED, "Đã nhận và kiểm tra hàng trả", actorId);
        document.setReceivedAt(LocalDateTime.now(orderClock));
        loyalty.reverse(document.getOrder(),document.getId(),document.getRefundAmount());
        Order order = document.getOrder();
        boolean fullReturn=order.getItems().stream().allMatch(item -> returnRepository.receivedQuantity(item.getId()) >= item.getQuantity());
        if (order.getStatus() == OrderStatus.SHIPPED || fullReturn) {
            OrderHistory entry = new OrderHistory();
            entry.setOrder(order); entry.setOldStatus(order.getStatus().name()); entry.setNewStatus("RETURNED");
            entry.setNote("Đã nhận lại toàn bộ hàng của đơn: " + document.getCode());
            entry.setCreatedBy(actor);
            order.getHistories().add(entry); order.setStatus(OrderStatus.RETURNED); order.setUpdatedAt(LocalDateTime.now(orderClock));
            if("PAID".equals(order.getPaymentStatus())) order.setPaymentStatus("REFUND_PENDING");
        }
        return ReturnResponse.from(document);
    }

    @Transactional
    public ReturnResponse complete(Long id, CompleteReturnRequest request, Long actorId) {
        return complete(id, request, actorId, false);
    }

    /** Called only after an authenticated gateway refund has been confirmed. */
    @Transactional
    public ReturnResponse completeVnPay(Long id, String note, Long actorId) {
        return complete(id, new CompleteReturnRequest("VNPAY", note), actorId, true);
    }

    private ReturnResponse complete(Long id, CompleteReturnRequest request, Long actorId, boolean gatewayConfirmed) {
        ReturnRequest document = lock(id);
        requireStatus(document, ReturnStatus.RECEIVED);
        if (document.getRefundAmount().signum() > 0 && document.getOrder().getOnlineTransactionId() != null
                && document.getOrder().getOnlineTransactionId().startsWith("VNPAY-") && !gatewayConfirmed)
            throw error("VNPAY_REFUND_REQUIRED", "Giao dịch VNPay phải hoàn qua API VNPay và được xác nhận trước khi hoàn tất");
        if (document.getRefundAmount().signum() > 0 && "NO_REFUND".equals(request.refundMethod()))
            throw error("REFUND_REQUIRED", "Phiếu có số tiền cần hoàn, phải xác nhận phương thức hoàn");
        if (document.getRefundAmount().signum() == 0 && !"NO_REFUND".equals(request.refundMethod()))
            throw error("NO_REFUND_DUE", "Phiếu không có tiền cần hoàn");
        document.setRefundMethod(request.refundMethod());
        document.setAdminNote(request.note());
        transition(document, ReturnStatus.COMPLETED, "Đã xử lý hoàn tiền: " + request.note(), actorId);
        document.setCompletedAt(LocalDateTime.now(orderClock));
        if (document.getOrder().getStatus() == OrderStatus.RETURNED && document.getRefundAmount().signum() > 0
                && returnRepository.pendingRefundCount(document.getOrder().getId())==0)
            document.getOrder().setPaymentStatus("REFUNDED");
        return ReturnResponse.from(document);
    }

    private ReturnRequest lock(Long id) {
        Long orderId = returnRepository.findOrderId(id).orElseThrow(() -> error("RETURN_NOT_FOUND", "Không tìm thấy phiếu trả"));
        orderService.lock(orderId); // All modifications lock the parent order first to serialize quantity limits.
        return returnRepository.findByIdForUpdate(id).orElseThrow(() -> error("RETURN_NOT_FOUND", "Không tìm thấy phiếu trả"));
    }

    private void requireStatus(ReturnRequest document, ReturnStatus status) {
        if (document.getStatus() != status) throw error("INVALID_RETURN_STATUS", "Trạng thái phiếu trả không cho phép thao tác");
    }

    private void transition(ReturnRequest document, ReturnStatus status, String note, Long actorId) {
        addHistory(document, document.getStatus(), status, note, actorId);
        document.setStatus(status); document.setUpdatedAt(LocalDateTime.now(orderClock));
    }

    private void addHistory(ReturnRequest document, ReturnStatus before, ReturnStatus after, String note, Long actorId) {
        ReturnHistory entry = new ReturnHistory();
        entry.setRequest(document); entry.setOldStatus(before == null ? null : before.name());
        entry.setNewStatus(after.name()); entry.setNote(note); entry.setChangedBy(userRepository.getReferenceById(actorId));
        entry.setCreatedAt(LocalDateTime.now(orderClock));
        document.getHistories().add(entry);
    }

    private BusinessException error(String code, String message) {
        return new BusinessException(HttpStatus.CONFLICT, code, message);
    }
}
