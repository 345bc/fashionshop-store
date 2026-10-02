package com.huit.zella.order;

import com.huit.zella.auth.User;
import com.huit.zella.auth.UserRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.inventory.InventoryService;
import com.huit.zella.orderreturn.ReturnRepository;
import com.huit.zella.productvariant.ProductVariant;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.*;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

@Service
@RequiredArgsConstructor
public class OrderService {
    private final OrderRepository orderRepository;
    private final UserRepository userRepository;
    private final InventoryService inventoryService;
    private final ReturnRepository returnRepository;
    private final Clock orderClock;
    private static final BigDecimal MAX_AMOUNT = new BigDecimal("9999999999999999.99");

    @Transactional(readOnly = true)
    public List<OrderResponse> list() {
        return orderRepository.findAll(Sort.by(Sort.Direction.DESC, "id")).stream().map(this::response).toList();
    }

    @Transactional(readOnly = true)
    public OrderResponse get(Long id) {
        return response(orderRepository.findById(id).orElseThrow(() -> error("ORDER_NOT_FOUND", "Không tìm thấy đơn hàng")));
    }

    @Transactional
    public OrderResponse create(CreateOrderRequest request, Long actorId) {
        if (!"ONLINE".equals(request.paymentMethod()))
            throw error("ONLINE_PAYMENT_ONLY", "Chỉ hỗ trợ thanh toán online");
        User customer = request.customerUserId() == null ? null : userRepository.findById(request.customerUserId())
            .orElseThrow(() -> error("CUSTOMER_NOT_FOUND", "Không tìm thấy khách hàng"));
        if (customer != null && (!customer.isActive() || customer.getCustomer() == null))
            throw error("INVALID_CUSTOMER", "Khách hàng không hoạt động hoặc chưa có hồ sơ");
        User actor = actorId == null ? null : userRepository.getReferenceById(actorId);
        Order order = new Order();
        order.setCode("ORD-" + UUID.randomUUID().toString().replace("-", "").substring(0, 28).toUpperCase(Locale.ROOT));
        order.setCustomer(customer);
        order.setRecipientName(request.recipientName().trim());
        order.setRecipientPhone(request.recipientPhone().trim());
        order.setAddress(request.address().trim());
        order.setNote(request.note());
        order.setShippingFee(request.shippingFee());
        order.setPaymentMethod(request.paymentMethod());
        order.setCreatedAt(LocalDateTime.now(orderClock));
        order.setUpdatedAt(order.getCreatedAt());
        order.setPaymentExpiresAt(order.getCreatedAt().plusMinutes(5));
        Map<Long, Integer> quantities = new TreeMap<>();
        for (CreateOrderRequest.Item line : request.items()) {
            long quantity = (long) quantities.getOrDefault(line.variantId(), 0) + line.quantity();
            if (quantity > Integer.MAX_VALUE) throw error("QUANTITY_OVERFLOW", "Số lượng vượt giới hạn");
            quantities.put(line.variantId(), (int) quantity);
        }
        for (Map.Entry<Long, Integer> line : quantities.entrySet()) {
            ProductVariant variant = inventoryService.lockVariant(line.getKey());
            if (!variant.isActive() || !variant.getProduct().isActive())
                throw error("VARIANT_INACTIVE", "Biến thể đã ngừng bán");
            if (variant.getStockQuantity() - variant.getReservedQuantity() < line.getValue())
                throw error("INSUFFICIENT_STOCK", "Không đủ tồn khả dụng cho SKU " + variant.getSku());
            OrderItem item = new OrderItem();
            item.setOrder(order); item.setVariant(variant); item.setProduct(variant.getProduct());
            item.setProductName(variant.getProduct().getName()); item.setSku(variant.getSku());
            item.setUnitPrice(variant.getPrice()); item.setQuantity(line.getValue());
            order.getItems().add(item);
            order.setSubtotal(order.getSubtotal().add(item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity()))));
        }
        order.setTotalAmount(order.getSubtotal().add(order.getShippingFee()));
        if (order.getTotalAmount().compareTo(MAX_AMOUNT) > 0) throw error("AMOUNT_OVERFLOW", "Tổng tiền vượt giới hạn");
        history(order, null, OrderStatus.PENDING, "Tạo đơn và giữ hàng 5 phút chờ thanh toán online", actor);
        orderRepository.save(order);
        for (OrderItem item : order.getItems()) {
            ProductVariant variant = item.getVariant();
            inventoryService.changeStockAndReservation(variant, variant.getStockQuantity(),
                variant.getReservedQuantity() + item.getQuantity(), "ORDER_RESERVE", order.getCode(), "Giữ hàng cho đơn", actor);
        }
        return response(order);
    }

    @Transactional
    public CheckoutOrderResponse createCheckout(CreateCheckoutOrderRequest request, Long actorId) {
        // Customer identity comes from authentication, never from a user id in the public request.
        BigDecimal fee = new BigDecimal("EXPRESS".equals(request.shippingMethod()) ? "45000" : "30000");
        OrderResponse created = create(new CreateOrderRequest(actorId, request.recipientName(), request.recipientPhone(),
            request.address(), request.note(), fee, "ONLINE", request.items()), actorId);
        Order order = orderRepository.findById(created.id()).orElseThrow();
        String token = UUID.randomUUID().toString() + UUID.randomUUID();
        order.setCheckoutTokenHash(hashToken(token));
        return checkoutResponse(order, token);
    }

    @Transactional(readOnly = true)
    public CheckoutOrderResponse checkoutStatus(String code, String token) {
        Order order = orderRepository.findByCode(code)
            .orElseThrow(() -> error("ORDER_NOT_FOUND", "Không tìm thấy đơn hàng"));
        if (order.getCheckoutTokenHash() == null || !MessageDigest.isEqual(
                order.getCheckoutTokenHash().getBytes(StandardCharsets.UTF_8), hashToken(token).getBytes(StandardCharsets.UTF_8)))
            throw error("ORDER_NOT_FOUND", "Không tìm thấy đơn hàng");
        return checkoutResponse(order, null);
    }

    /**
     * Internal integration point for a verified gateway callback.
     * No production gateway callback endpoint is exposed until a provider is integrated.
     */
    @Transactional
    public OrderResponse recordOnlinePayment(Long id, BigDecimal amount, String transactionId) {
        Order order = lock(id);
        if (!"ONLINE".equals(order.getPaymentMethod()) || amount == null || amount.compareTo(order.getTotalAmount()) != 0)
            throw error("INVALID_PAYMENT_AMOUNT", "Khoản thanh toán không khớp đơn online");
        if (transactionId == null || transactionId.isBlank() || transactionId.length() > 100)
            throw error("INVALID_TRANSACTION", "Mã giao dịch thanh toán không hợp lệ");
        if (transactionId.equals(order.getOnlineTransactionId())) return response(order);
        if (order.getOnlineTransactionId() != null || orderRepository.existsByOnlineTransactionIdAndIdNot(transactionId, id))
            throw error("DUPLICATE_TRANSACTION", "Giao dịch đã được ghi nhận cho đơn khác hoặc đơn đã thanh toán");
        if (order.getStatus() == OrderStatus.PENDING && expired(order)) cancelOrder(order, "Hết 5 phút chờ thanh toán", null);
        if (order.getStatus() != OrderStatus.PENDING && order.getStatus() != OrderStatus.CANCELLED)
            throw error("INVALID_PAYMENT_STATUS", "Trạng thái đơn không cho phép ghi nhận thanh toán");
        order.setOnlineTransactionId(transactionId);
        if (order.getStatus() == OrderStatus.CANCELLED) {
            order.setPaymentStatus("REFUND_PENDING");
            history(order, order.getStatus(), order.getStatus(),
                "Thanh toán về sau khi đơn bị hủy, cần hoàn tiền. Giao dịch: " + transactionId, null);
        } else {
            order.setPaymentStatus("PAID");
            transition(order, OrderStatus.CONFIRMED, "Tự xác nhận sau thanh toán online. Giao dịch: " + transactionId, null);
        }
        orderRepository.flush();
        return response(order);
    }

    @Transactional
    public boolean expire(Long id) {
        Order order = orderRepository.findByIdForUpdate(id).orElse(null);
        if (order == null || !order.isInventoryManaged() || order.getStatus() != OrderStatus.PENDING
                || !"PENDING".equals(order.getPaymentStatus()) || !expired(order)) return false;
        cancelOrder(order, "Hết 5 phút chờ thanh toán", null);
        order.setPaymentStatus("EXPIRED");
        return true;
    }

    private boolean expired(Order order) {
        return order.getPaymentExpiresAt() != null && !order.getPaymentExpiresAt().isAfter(LocalDateTime.now(orderClock));
    }

    @Transactional
    public OrderResponse ship(Long id, Long actorId) {
        Order order = lock(id);
        requireStatus(order, OrderStatus.CONFIRMED);
        if (!"PAID".equals(order.getPaymentStatus()))
            throw error("ORDER_NOT_PAID", "Đơn phải thanh toán thành công trước khi xuất");
        User actor = userRepository.getReferenceById(actorId);
        for (OrderItem item : orderedItems(order)) {
            ProductVariant variant = inventoryService.lockVariant(item.getVariant().getId());
            if (variant.getReservedQuantity() < item.getQuantity() || variant.getStockQuantity() < item.getQuantity())
                throw error("INVALID_RESERVED_STOCK", "Không đủ số hàng đã giữ để xuất");
            item.setUnitCost(variant.getCostPrice());
            inventoryService.changeStockAndReservation(variant, variant.getStockQuantity() - item.getQuantity(),
                variant.getReservedQuantity() - item.getQuantity(), "ORDER_SHIP", order.getCode(), "Xuất hàng giao khách", actor);
        }
        transition(order, OrderStatus.SHIPPED, "Xuất kho và giao vận", actorId);
        return response(order);
    }

    @Transactional
    public OrderResponse deliver(Long id, Long actorId) {
        Order order = lock(id);
        requireStatus(order, OrderStatus.SHIPPED);
        if (order.getItems().stream().anyMatch(i -> returnRepository.committedQuantity(i.getId()) > 0))
            throw error("ORDER_HAS_RETURN", "Đơn đang xử lý hàng giao không thành công, không thể xác nhận giao");
        transition(order, OrderStatus.DELIVERED, "Xác nhận giao thành công", actorId);
        return response(order);
    }

    @Transactional
    public OrderResponse cancel(Long id, String reason, Long actorId) {
        Order order = lock(id);
        cancelOrder(order, reason, actorId);
        return response(order);
    }

    private void cancelOrder(Order order, String reason, Long actorId) {
        if (order.getStatus() != OrderStatus.PENDING && order.getStatus() != OrderStatus.CONFIRMED)
            throw error("INVALID_ORDER_STATUS", "Chỉ hủy trước khi xuất kho. Hàng đã xuất phải lập phiếu trả");
        User actor = actorId == null ? null : userRepository.getReferenceById(actorId);
        for (OrderItem item : orderedItems(order)) {
            ProductVariant variant = inventoryService.lockVariant(item.getVariant().getId());
            if (variant.getReservedQuantity() < item.getQuantity())
                throw error("INVALID_RESERVED_STOCK", "Số hàng đã giữ không hợp lệ");
            inventoryService.changeStockAndReservation(variant, variant.getStockQuantity(),
                variant.getReservedQuantity() - item.getQuantity(), "ORDER_RELEASE", order.getCode(), reason, actor);
        }
        if ("PAID".equals(order.getPaymentStatus())) order.setPaymentStatus("REFUND_PENDING");
        transition(order, OrderStatus.CANCELLED, reason, actorId);
    }

    @Transactional
    public OrderResponse refunded(Long id, String note, Long actorId) {
        Order order = lock(id);
        requireStatus(order, OrderStatus.CANCELLED);
        if (!"REFUND_PENDING".equals(order.getPaymentStatus()))
            throw error("INVALID_PAYMENT_STATUS", "Đơn không có khoản cần hoàn");
        order.setPaymentStatus("REFUNDED");
        history(order, order.getStatus(), order.getStatus(), "Đã hoàn " + order.getTotalAmount() + ": " + note,
            userRepository.getReferenceById(actorId));
        return response(order);
    }

    public Order lock(Long id) {
        Order order = orderRepository.findByIdForUpdate(id)
            .orElseThrow(() -> error("ORDER_NOT_FOUND", "Không tìm thấy đơn hàng"));
        if (!order.isInventoryManaged())
            throw error("LEGACY_ORDER", "Đơn cũ chưa theo dõi giữ/xuất kho; không tự động thay đổi tồn");
        return order;
    }

    private OrderResponse response(Order order) {
        return new OrderResponse(order.getId(), order.getCode(), order.getCustomer() == null ? null : order.getCustomer().getId(),
            order.getCustomer() == null ? order.getRecipientName() + " (khách vãng lai)" :
                order.getCustomer().getCustomer() == null ? order.getCustomer().getUserName() : order.getCustomer().getCustomer().getFullName(),
            order.getRecipientName(), order.getRecipientPhone(), order.getAddress(), order.getNote(),
            order.getStatus().name(), order.getPaymentStatus(), order.getPaymentMethod(), order.isInventoryManaged(),
            order.getSubtotal(), order.getShippingFee(), order.getTotalAmount(), order.getCreatedAt().atOffset(ZoneOffset.UTC),
            order.getItems().stream().map(i -> new OrderResponse.Item(i.getId(), i.getVariant().getId(),
                i.getProductName(), i.getSku(), i.getQuantity(), i.getUnitPrice(),
                i.getUnitPrice().multiply(BigDecimal.valueOf(i.getQuantity())), Math.toIntExact(returnRepository.committedQuantity(i.getId())))).toList(),
            order.getHistories().stream().map(h -> new OrderResponse.History(h.getOldStatus(), h.getNewStatus(),
                h.getNote(), h.getCreatedBy() == null ? "Hệ thống" : h.getCreatedBy().getUserName(), h.getCreatedAt().atOffset(ZoneOffset.UTC))).toList(),
            order.getPaymentExpiresAt() == null ? null : order.getPaymentExpiresAt().atOffset(ZoneOffset.UTC));
    }

    private List<OrderItem> orderedItems(Order order) {
        return order.getItems().stream().sorted(Comparator.comparing(i -> i.getVariant().getId())).toList();
    }

    private void requireStatus(Order order, OrderStatus status) {
        if (order.getStatus() != status) throw error("INVALID_ORDER_STATUS", "Trạng thái đơn không cho phép thao tác này");
    }

    private void transition(Order order, OrderStatus status, String note, Long actorId) {
        history(order, order.getStatus(), status, note, actorId == null ? null : userRepository.getReferenceById(actorId));
        order.setStatus(status);
        order.setUpdatedAt(LocalDateTime.now(orderClock));
    }

    private void history(Order order, OrderStatus before, OrderStatus after, String note, User actor) {
        OrderHistory entry = new OrderHistory();
        entry.setOrder(order); entry.setOldStatus(before == null ? null : before.name());
        entry.setNewStatus(after.name()); entry.setNote(note); entry.setCreatedBy(actor);
        entry.setCreatedAt(LocalDateTime.now(orderClock));
        order.getHistories().add(entry);
    }

    private CheckoutOrderResponse checkoutResponse(Order order, String token) {
        return new CheckoutOrderResponse(order.getId(), order.getCode(), order.getStatus().name(),
            order.getPaymentStatus(), order.getTotalAmount(),
            order.getPaymentExpiresAt() == null ? null : order.getPaymentExpiresAt().atOffset(ZoneOffset.UTC), token);
    }

    private String hashToken(String token) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(token.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException(exception);
        }
    }

    private BusinessException error(String code, String message) {
        return new BusinessException(HttpStatus.CONFLICT, code, message);
    }
}
