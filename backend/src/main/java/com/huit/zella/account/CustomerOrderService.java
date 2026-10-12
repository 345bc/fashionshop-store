package com.huit.zella.account;

import com.huit.zella.auth.UserRepository;
import com.huit.zella.cart.*;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.*;
import com.huit.zella.orderreturn.*;
import com.huit.zella.review.*;
import com.huit.zella.variantimage.VariantImageRepository;
import jakarta.validation.constraints.*;
import java.time.*;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor
public class CustomerOrderService {
    private final OrderRepository orders;
    private final OrderService orderService;
    private final ReturnRepository returns;
    private final ReturnService returnService;
    private final ProductReviewRepository reviews;
    private final UserRepository users;
    private final VariantImageRepository images;
    private final CartService cart;
    public record ReviewRequest(@NotNull @Min(1) @Max(5) Integer rating, @Size(max = 1000) String comment) {}

    @Transactional(readOnly = true)
    public Page<CustomerOrderResponse> list(Long userId, String status, boolean purchases, Pageable pageable) {
        OrderStatus filter = null;
        if (status != null && !status.isBlank() && !"ALL".equals(status)) {
            try { filter = OrderStatus.valueOf(status); }
            catch (IllegalArgumentException ex) { throw error("INVALID_STATUS", "Trạng thái không hợp lệ"); }
        }
        Page<Order> page = purchases ? orders.findPurchases(userId, pageable) : orders.findCustomerOrders(userId, filter, pageable);
        return map(page);
    }

    @Transactional(readOnly = true)
    public CustomerOrderResponse get(Long id, Long userId) { return map(new PageImpl<>(List.of(owned(id, userId, false)))).getContent().getFirst(); }

    @Transactional
    public CustomerOrderResponse cancel(Long id, Long userId) {
        Order order = owned(id, userId, true);
        if (order.getStatus() != OrderStatus.PENDING || !"PENDING".equals(order.getPaymentStatus())) throw error("CANNOT_CANCEL", "Chỉ hủy đơn chưa thanh toán");
        orderService.cancel(id, "Khách hàng hủy đơn trước thanh toán", userId);
        return get(id, userId);
    }

    @Transactional
    public CartResponse reorder(Long id, Long userId, String key) {
        cart.prepareCheckout(userId);
        Order order = owned(id, userId, false);
        return cart.merge(userId, new MergeCartRequest(key, order.getItems().stream().map(item -> new CartItemRequest(item.getVariant().getId(), item.getQuantity())).toList()));
    }

    @Transactional
    public ReturnResponse requestReturn(Long id, Long userId, CreateReturnRequest request) {
        Order order = owned(id, userId, true);
        if (!id.equals(request.orderId()) || order.getStatus() != OrderStatus.DELIVERED) throw error("CANNOT_RETURN", "Chỉ yêu cầu trả hàng sau khi giao thành công");
        return returnService.create(request, userId);
    }

    @Transactional
    public CustomerOrderResponse.Review review(Long id, Long itemId, Long userId, ReviewRequest request) {
        Order order = owned(id, userId, true);
        OrderItem item = order.getItems().stream().filter(line -> line.getId().equals(itemId)).findFirst().orElseThrow(() -> error("ITEM_NOT_FOUND", "Không tìm thấy sản phẩm trong đơn"));
        if (order.getStatus() != OrderStatus.DELIVERED || !"PAID".equals(order.getPaymentStatus())
                || returns.committedQuantity(itemId) >= item.getQuantity()) throw error("CANNOT_REVIEW", "Chỉ đánh giá sản phẩm đã giao và chưa trả hết");
        ProductReview review = reviews.findByOrderItemId(itemId).orElseGet(ProductReview::new);
        if (review.getId() != null && review.isHidden()) throw error("REVIEW_HIDDEN", "Đánh giá đang bị ẩn; vui lòng liên hệ cửa hàng");
        review.setProduct(item.getProduct()); review.setOrder(order); review.setOrderItem(item);
        review.setCustomer(users.findById(userId).orElseThrow().getCustomer());
        review.setRating(request.rating()); review.setComment(request.comment() == null ? null : request.comment().trim()); review.setUpdatedAt(Instant.now());
        reviews.saveAndFlush(review);
        return new CustomerOrderResponse.Review(review.getId(), review.getRating(), review.getComment(), review.isHidden());
    }

    private Order owned(Long id, Long userId, boolean lock) {
        Order order = (lock ? orders.findByIdForUpdate(id) : orders.findById(id)).orElseThrow(() -> error("ORDER_NOT_FOUND", "Không tìm thấy đơn hàng"));
        if (order.getCustomer() == null || !order.getCustomer().getId().equals(userId)) throw error("ORDER_NOT_FOUND", "Không tìm thấy đơn hàng");
        return order;
    }

    private Page<CustomerOrderResponse> map(Page<Order> page) {
        if (page.isEmpty()) return page.map(order -> null);
        var reviewMap = new HashMap<Long, ProductReview>();
        reviews.findByOrderIdIn(page.map(Order::getId).getContent()).forEach(review -> reviewMap.put(review.getOrderItem().getId(), review));
        var imageMap = new HashMap<Long, String>();
        var variantIds = page.stream().flatMap(order -> order.getItems().stream()).map(item -> item.getVariant().getId()).distinct().toList();
        if (!variantIds.isEmpty()) images.findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(variantIds).forEach(image -> imageMap.putIfAbsent(image.getVariant().getId(), image.getImageUrl()));
        return page.map(order -> new CustomerOrderResponse(order.getId(), order.getCode(), order.getStatus().name(), order.getPaymentStatus(),
                order.getCreatedAt().atOffset(ZoneOffset.UTC), order.getSubtotal(), order.getShippingFee(), order.getDiscountAmount(), order.getTotalAmount(),
                order.getRecipientName(), order.getRecipientPhone(), order.getAddress(), order.getItems().stream().map(item -> {
                    var review = reviewMap.get(item.getId());
                    int returned = Math.toIntExact(returns.committedQuantity(item.getId()));
                    return new CustomerOrderResponse.Item(item.getId(), item.getVariant().getId(), item.getProductName(), item.getSku(), item.getProduct().getSlug(),
                            imageMap.get(item.getVariant().getId()), item.getVariant().getColor().getName(), item.getVariant().getSize().getName(), item.getQuantity(), item.getUnitPrice(), returned,
                            order.getStatus() == OrderStatus.DELIVERED && "PAID".equals(order.getPaymentStatus()) && returned < item.getQuantity() && (review == null || !review.isHidden()),
                            review == null ? null : new CustomerOrderResponse.Review(review.getId(), review.getRating(), review.getComment(), review.isHidden()));
                }).toList(), order.getHistories().stream().map(history -> new CustomerOrderResponse.History(history.getNewStatus(), history.getNote(), history.getCreatedAt().atOffset(ZoneOffset.UTC))).toList()));
    }
    private BusinessException error(String code, String message) { return new BusinessException(HttpStatus.CONFLICT, code, message); }
}
