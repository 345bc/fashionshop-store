package com.huit.zella.cart;

import com.huit.zella.auth.User;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.CreateOrderRequest;
import com.huit.zella.productimage.ProductImageRepository;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.productvariant.ProductVariantRepository;
import com.huit.zella.variantimage.VariantImageRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.LockModeType;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class CartService {
    private final com.huit.zella.promotion.PromotionPricingService promotionPricing;
    private final CartRepository cartRepository;
    private final ProductVariantRepository variantRepository;
    private final VariantImageRepository variantImageRepository;
    private final ProductImageRepository productImageRepository;
    private final EntityManager entityManager;

    @Transactional(readOnly=true)
    public List<com.huit.zella.product.Product> productsForPricing(List<Long> ids) {
        return variantRepository.findCartVariants(ids).stream().map(ProductVariant::getProduct).distinct().toList();
    }

    @Transactional(readOnly = true)
    public CartResponse get(Long userId) {
        return cartRepository.findByUserId(userId).map(cart -> quote(lines(cart))).orElseGet(() -> quote(List.of()));
    }

    @Transactional(readOnly = true)
    public CartResponse quote(List<CartItemRequest> requested) {
        Map<Long, Integer> quantities = aggregate(requested);
        if (quantities.isEmpty()) return new CartResponse(List.of(), 0, BigDecimal.ZERO);
        List<ProductVariant> variants = variantRepository.findCartVariants(new ArrayList<>(quantities.keySet()));
        Map<Long, ProductVariant> byId = new HashMap<>();
        variants.forEach(v -> byId.put(v.getId(), v));
        Map<Long, String> images = new HashMap<>();
        for (var image : variantImageRepository.findByVariantIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(new ArrayList<>(quantities.keySet())))
            images.putIfAbsent(image.getVariant().getId(), image.getImageUrl());
        Map<Long, String> productImages = new HashMap<>();
        List<Long> productIds = variants.stream().map(v -> v.getProduct().getId()).distinct().toList();
        if (!productIds.isEmpty())
            for (var image : productImageRepository.findByProductIdInOrderByIsPrimaryDescDisplayOrderAscIdAsc(productIds))
                productImages.putIfAbsent(image.getProduct().getId(), image.getImageUrl());
        var offers = promotionPricing.offers(variants.stream().map(ProductVariant::getProduct).toList());
        List<CartResponse.Item> items = new ArrayList<>();
        for (var line : quantities.entrySet()) {
            ProductVariant v = byId.get(line.getKey());
            if (v == null) {
                items.add(new CartResponse.Item(line.getKey(), null, "Sản phẩm không còn tồn tại", null, null,
                        null, null, null, line.getValue(), 0, BigDecimal.ZERO, BigDecimal.ZERO, false, "Biến thể đã bị xóa"));
                continue;
            }
            String reason = unavailableReason(v, line.getValue());
            BigDecimal price = promotionPricing.price(v.getProduct(),v.getPrice(),offers);
            BigDecimal total = price.multiply(BigDecimal.valueOf(line.getValue()));
            items.add(new CartResponse.Item(v.getId(), v.getProduct().getId(), v.getProduct().getName(), v.getProduct().getSlug(),
                    v.getSku(), v.getColor().getName(), v.getSize().getName(),
                    images.getOrDefault(v.getId(), productImages.get(v.getProduct().getId())), line.getValue(), available(v),
                    price, total, reason == null, reason));
        }
        return new CartResponse(items, quantities.values().stream().mapToInt(Integer::intValue).sum(),
                items.stream().map(CartResponse.Item::lineTotal).reduce(BigDecimal.ZERO, BigDecimal::add));
    }

    @Transactional
    public CartResponse add(Long userId, CartItemRequest request) {
        Cart cart = lockCart(userId);
        CartItem existing = item(cart, request.variantId());
        int quantity = Math.addExact(existing == null ? 0 : existing.getQuantity(), request.quantity());
        put(cart, request.variantId(), quantity, true);
        cartRepository.flush();
        return quote(lines(cart));
    }

    @Transactional
    public CartResponse update(Long userId, Long variantId, int quantity) {
        Cart cart = lockCart(userId);
        if (item(cart, variantId) == null) throw error("CART_ITEM_NOT_FOUND", "Sản phẩm không có trong giỏ");
        put(cart, variantId, quantity, true);
        cartRepository.flush();
        return quote(lines(cart));
    }

    @Transactional
    public CartResponse remove(Long userId, Long variantId) {
        Cart cart = lockCart(userId);
        if (variantId == null) cart.getItems().clear();
        else cart.getItems().removeIf(i -> i.getVariant().getId().equals(variantId));
        cart.setUpdatedAt(LocalDateTime.now());
        cartRepository.flush();
        return quote(lines(cart));
    }

    @Transactional
    public CartResponse replace(Long userId, Long variantId, CartItemRequest request) {
        Cart cart = lockCart(userId);
        CartItem old = item(cart, variantId);
        if (old == null) throw error("CART_ITEM_NOT_FOUND", "Sản phẩm không có trong giỏ");
        if (variantId.equals(request.variantId())) return update(userId, variantId, request.quantity());
        CartItem target = item(cart, request.variantId());
        cart.getItems().remove(old);
        put(cart, request.variantId(), Math.addExact(request.quantity(), target == null ? 0 : target.getQuantity()), true);
        cartRepository.flush();
        return quote(lines(cart));
    }

    @Transactional
    public CartResponse merge(Long userId, MergeCartRequest request) {
        Cart cart = lockCart(userId);
        Set<String> keys = new LinkedHashSet<>(Arrays.asList(cart.getMergedGuestKeys().split(",")));
        if (!keys.contains(request.mergeKey())) {
            Map<Long, Integer> quantities = aggregate(request.items());
            for (var line : quantities.entrySet()) {
                CartItem existing = item(cart, line.getKey());
                // Keep unavailable lines visible after login so the customer can fix or remove them.
                put(cart, line.getKey(), Math.addExact(line.getValue(), existing == null ? 0 : existing.getQuantity()), false);
            }
            keys.remove(""); keys.add(request.mergeKey());
            cart.setMergedGuestKeys(String.join(",", keys));
        }
        cartRepository.flush();
        return quote(lines(cart));
    }

    /** Called inside the order transaction: failed orders leave the cart unchanged. */
    @Transactional
    public void consume(Long userId, List<CreateOrderRequest.Item> purchased) {
        if (userId == null) return;
        Cart cart = lockCart(userId);
        Map<Long, Integer> quantities = new HashMap<>();
        purchased.forEach(i -> quantities.merge(i.variantId(), i.quantity(), Math::addExact));
        cart.getItems().removeIf(i -> {
            int remaining = i.getQuantity() - quantities.getOrDefault(i.getVariant().getId(), 0);
            if (remaining <= 0) return true;
            i.setQuantity(remaining); return false;
        });
        cart.setUpdatedAt(LocalDateTime.now());
    }

    @Transactional
    public void prepareCheckout(Long userId) { if (userId != null) lockCart(userId); }

    private Cart lockCart(Long userId) {
        // Serialize by user, including the very first cart creation (the cart row may not exist yet).
        User user = entityManager.find(User.class, userId, LockModeType.PESSIMISTIC_WRITE);
        if (user == null || !user.isActive()) throw error("INVALID_USER", "Tài khoản không hoạt động");
        return cartRepository.findByUserId(userId).orElseGet(() -> {
            Cart cart = new Cart(); cart.setUser(user); return cartRepository.save(cart);
        });
    }

    private void put(Cart cart, Long variantId, int quantity, boolean validateStock) {
        if (quantity < 1 || quantity > 999) throw error("INVALID_QUANTITY", "Số lượng phải từ 1 đến 999");
        ProductVariant variant = variantRepository.findById(variantId)
                .orElseThrow(() -> error("VARIANT_NOT_FOUND", "Không tìm thấy biến thể"));
        String reason = unavailableReason(variant, quantity);
        if (validateStock && reason != null) throw error("VARIANT_UNAVAILABLE", reason);
        CartItem line = item(cart, variantId);
        if (line == null) {
            if (cart.getItems().size() >= 200) throw error("CART_LIMIT", "Giỏ hàng tối đa 200 biến thể");
            line = new CartItem(); line.setCart(cart); line.setVariant(variant); cart.getItems().add(line);
        }
        line.setQuantity(quantity);
        cart.setUpdatedAt(LocalDateTime.now());
    }

    static Map<Long, Integer> aggregate(List<CartItemRequest> items) {
        Map<Long, Integer> result = new LinkedHashMap<>();
        if (items.size() > 200) throw error("CART_LIMIT", "Giỏ hàng tối đa 200 biến thể");
        for (CartItemRequest item : items) {
            long quantity = (long) result.getOrDefault(item.variantId(), 0) + item.quantity();
            if (item.variantId() <= 0 || quantity < 1 || quantity > 999)
                throw error("INVALID_QUANTITY", "Số lượng phải từ 1 đến 999");
            result.put(item.variantId(), (int) quantity);
        }
        return result;
    }

    static int available(ProductVariant v) { return Math.max(0, v.getStockQuantity() - v.getReservedQuantity()); }
    static String unavailableReason(ProductVariant v, int quantity) {
        if (!v.isActive() || !v.getProduct().isActive() || !Boolean.TRUE.equals(v.getProduct().getCategory().getIsActive())) return "Sản phẩm đã ngừng bán";
        if (available(v) == 0) return "Sản phẩm đã hết hàng";
        if (quantity > available(v)) return "Chỉ còn " + available(v) + " sản phẩm có thể mua";
        return null;
    }
    private CartItem item(Cart cart, Long id) { return cart.getItems().stream().filter(i -> i.getVariant().getId().equals(id)).findFirst().orElse(null); }
    private List<CartItemRequest> lines(Cart cart) { return cart.getItems().stream().map(i -> new CartItemRequest(i.getVariant().getId(), i.getQuantity())).toList(); }
    private static BusinessException error(String code, String message) { return new BusinessException(HttpStatus.CONFLICT, code, message); }
}
