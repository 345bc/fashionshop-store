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
import java.util.*;

@Service
@RequiredArgsConstructor
public class ReturnService {
    private final ReturnRepository returnRepository;
    private final OrderService orderService;
    private final UserRepository userRepository;
    private final InventoryService inventoryService;

    @Transactional(readOnly = true)
    public List<ReturnResponse> list(Long orderId) {
        return returnRepository.findByOrderIdOrderByIdDesc(orderId).stream().map(ReturnResponse::from).toList();
    }

    @Transactional
    public ReturnResponse create(CreateReturnRequest request, Long actorId) {
        Order order = orderService.lock(request.orderId());
        if (order.getStatus() != OrderStatus.SHIPPED && order.getStatus() != OrderStatus.DELIVERED)
            throw error("ORDER_NOT_SHIPPED", "Chỉ lập phiếu trả cho đơn đã xuất kho");
        ReturnRequest document = new ReturnRequest();
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
        document.setApprovedAt(LocalDateTime.now(ZoneOffset.UTC));
        return ReturnResponse.from(document);
    }

    @Transactional
    public ReturnResponse reject(Long id, String note, Long actorId) {
        ReturnRequest document = lock(id);
        requireStatus(document, ReturnStatus.PENDING);
        transition(document, ReturnStatus.REJECTED, note, actorId);
        document.setRejectedAt(LocalDateTime.now(ZoneOffset.UTC));
        return ReturnResponse.from(document);
    }

    @Transactional
    public ReturnResponse cancel(Long id, String note, Long actorId) {
        ReturnRequest document = lock(id);
        if (document.getStatus() != ReturnStatus.PENDING && document.getStatus() != ReturnStatus.APPROVED)
            throw error("INVALID_RETURN_STATUS", "Chỉ hủy phiếu chưa nhận hàng");
        transition(document, ReturnStatus.CANCELLED, note, actorId);
        document.setCancelledAt(LocalDateTime.now(ZoneOffset.UTC));
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
        document.setRefundAmount("PAID".equals(document.getOrder().getPaymentStatus()) ? refund : BigDecimal.ZERO);
        transition(document, ReturnStatus.RECEIVED, "Đã nhận và kiểm tra hàng trả", actorId);
        document.setReceivedAt(LocalDateTime.now(ZoneOffset.UTC));
        Order order = document.getOrder();
        if (order.getStatus() == OrderStatus.SHIPPED) {
            OrderHistory entry = new OrderHistory();
            entry.setOrder(order); entry.setOldStatus(order.getStatus().name()); entry.setNewStatus("RETURNED");
            entry.setNote("Đã nhận lại kiện hàng giao không thành công: " + document.getCode());
            entry.setCreatedBy(actor);
            order.getHistories().add(entry); order.setStatus(OrderStatus.RETURNED); order.setUpdatedAt(LocalDateTime.now(ZoneOffset.UTC));
        }
        return ReturnResponse.from(document);
    }

    @Transactional
    public ReturnResponse complete(Long id, CompleteReturnRequest request, Long actorId) {
        ReturnRequest document = lock(id);
        requireStatus(document, ReturnStatus.RECEIVED);
        if (document.getRefundAmount().signum() > 0 && "NO_REFUND".equals(request.refundMethod()))
            throw error("REFUND_REQUIRED", "Phiếu có số tiền cần hoàn, phải xác nhận phương thức hoàn");
        if (document.getRefundAmount().signum() == 0 && !"NO_REFUND".equals(request.refundMethod()))
            throw error("NO_REFUND_DUE", "Phiếu không có tiền cần hoàn");
        document.setRefundMethod(request.refundMethod());
        document.setAdminNote(request.note());
        transition(document, ReturnStatus.COMPLETED, "Đã xử lý hoàn tiền: " + request.note(), actorId);
        document.setCompletedAt(LocalDateTime.now(ZoneOffset.UTC));
        if (document.getOrder().getStatus() == OrderStatus.RETURNED && document.getRefundAmount().signum() > 0)
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
        document.setStatus(status); document.setUpdatedAt(LocalDateTime.now(ZoneOffset.UTC));
    }

    private void addHistory(ReturnRequest document, ReturnStatus before, ReturnStatus after, String note, Long actorId) {
        ReturnHistory entry = new ReturnHistory();
        entry.setRequest(document); entry.setOldStatus(before == null ? null : before.name());
        entry.setNewStatus(after.name()); entry.setNote(note); entry.setChangedBy(userRepository.getReferenceById(actorId));
        document.getHistories().add(entry);
    }

    private BusinessException error(String code, String message) {
        return new BusinessException(HttpStatus.CONFLICT, code, message);
    }
}
