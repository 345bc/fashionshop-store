package com.huit.zella.cart;

import com.huit.zella.auth.User;
import com.huit.zella.category.Category;
import com.huit.zella.color.Color;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.order.CreateOrderRequest;
import com.huit.zella.product.Product;
import com.huit.zella.productimage.ProductImageRepository;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.productvariant.ProductVariantRepository;
import com.huit.zella.size.Size;
import com.huit.zella.variantimage.VariantImageRepository;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.lang.reflect.Proxy;
import java.math.BigDecimal;
import java.util.*;
import java.util.function.BiFunction;
import static org.junit.jupiter.api.Assertions.*;

/** Repository fakes keep business tests independent of a database and agent attachment. */
class CartServiceTest {
    private CartService service;
    private final Map<Long, Cart> carts = new HashMap<>();
    private final Map<Long, ProductVariant> variants = new HashMap<>();

    @BeforeEach void setup() {
        variants.put(10L, variant(10L)); variants.put(20L, variant(20L));
        CartRepository repository = fake(CartRepository.class, (method, args) -> switch (method) {
            case "findByUserId" -> Optional.ofNullable(carts.get((Long) args[0]));
            case "save" -> { Cart cart = (Cart) args[0]; carts.put(cart.getUser().getId(), cart); yield cart; }
            case "flush" -> null;
            default -> throw new UnsupportedOperationException(method);
        });
        ProductVariantRepository variantRepository = fake(ProductVariantRepository.class, (method, args) -> switch (method) {
            case "findById" -> Optional.ofNullable(variants.get((Long) args[0]));
            case "findCartVariants" -> variants.values().stream().filter(v -> ((List<?>) args[0]).contains(v.getId())).toList();
            default -> throw new UnsupportedOperationException(method);
        });
        EntityManager em = fake(EntityManager.class, (method, args) -> {
            if (!method.equals("find")) throw new UnsupportedOperationException(method);
            User user = new User(); user.setId((Long) args[1]); return user;
        });
        service = new CartService(new com.huit.zella.promotion.PromotionPricingService(org.mockito.Mockito.mock(com.huit.zella.promotion.PromotionRepository.class), java.time.Clock.systemUTC()), repository, variantRepository,
                fake(VariantImageRepository.class, (method, args) -> List.of()),
                fake(ProductImageRepository.class, (method, args) -> List.of()), em);
    }

    @Test void addingSameVariantAccumulatesButDoesNotReserveStock() {
        service.add(1L, new CartItemRequest(10L, 2));
        CartResponse result = service.add(1L, new CartItemRequest(10L, 3));
        assertEquals(1, result.items().size()); assertEquals(5, result.totalQuantity());
        assertEquals(new BigDecimal("1500"), result.subtotal());
        assertEquals(2, variants.get(10L).getReservedQuantity());
        assertThrows(BusinessException.class, () -> service.add(1L, new CartItemRequest(10L, 4)));
        assertEquals(5, service.get(1L).totalQuantity());
    }

    @Test void cartOperationsCannotChangeAnotherUsersCart() {
        service.add(1L, new CartItemRequest(10L, 2));
        service.add(2L, new CartItemRequest(10L, 4));
        service.remove(2L, 10L);
        assertEquals(2, service.get(1L).totalQuantity());
        assertEquals(0, service.get(2L).totalQuantity());
        assertThrows(BusinessException.class, () -> service.update(2L, 10L, 3));
    }

    @Test void mergeIsRepeatableAndKeepsInsufficientStockVisible() {
        service.add(1L, new CartItemRequest(10L, 3));
        MergeCartRequest request = new MergeCartRequest(UUID.randomUUID().toString(), List.of(new CartItemRequest(10L, 7)));
        CartResponse first = service.merge(1L, request);
        CartResponse second = service.merge(1L, request);
        assertEquals(10, first.totalQuantity()); assertEquals(10, second.totalQuantity());
        assertFalse(second.items().getFirst().purchasable());
        assertEquals(8, second.items().getFirst().availableQuantity());
    }

    @Test void checkoutConsumesOnlyPurchasedQuantitiesAndPreservesOtherLines() {
        service.add(1L, new CartItemRequest(10L, 5)); service.add(1L, new CartItemRequest(20L, 4));
        service.consume(1L, List.of(new CreateOrderRequest.Item(10L, 2)));
        CartResponse result = service.get(1L);
        assertEquals(7, result.totalQuantity()); assertEquals(2, result.items().size());
        assertEquals(3, result.items().stream().filter(i -> i.variantId().equals(10L)).findFirst().orElseThrow().quantity());
    }

    @Test void replacingVariantMergesIntoTargetLine() {
        service.add(1L, new CartItemRequest(10L, 2)); service.add(1L, new CartItemRequest(20L, 3));
        CartResponse result = service.replace(1L, 10L, new CartItemRequest(20L, 2));
        assertEquals(1, result.items().size()); assertEquals(20L, result.items().getFirst().variantId());
        assertEquals(5, result.totalQuantity());
    }

    @Test void quoteUsesLivePriceAndReportsDeletedOrInactiveVariants() {
        variants.get(10L).setPrice(new BigDecimal("450")); variants.get(20L).setActive(false);
        CartResponse result = service.quote(List.of(new CartItemRequest(10L, 2), new CartItemRequest(20L, 1), new CartItemRequest(30L, 1)));
        assertEquals(new BigDecimal("1200"), result.subtotal());
        assertEquals(1, result.items().stream().filter(CartResponse.Item::purchasable).count());
        assertEquals(4, result.totalQuantity());
    }

    @Test void duplicateLinesAreAggregatedAndBounded() {
        assertEquals(5, CartService.aggregate(List.of(new CartItemRequest(10L, 2), new CartItemRequest(10L, 3))).get(10L));
        assertThrows(BusinessException.class, () -> CartService.aggregate(List.of(new CartItemRequest(10L, 999), new CartItemRequest(10L, 1))));
    }

    private ProductVariant variant(Long id) {
        Category category = new Category(); category.setId(1L);
        Product product = new Product(); product.setId(1L); product.setName("Áo test"); product.setSlug("ao-test"); product.setCategory(category);
        Color color = new Color(); color.setName("Blue");
        Size size = new Size(); size.setName("M");
        ProductVariant variant = new ProductVariant(); variant.setId(id); variant.setProduct(product);
        variant.setColor(color); variant.setSize(size); variant.setSku("TEST-" + id);
        variant.setPrice(new BigDecimal("300")); variant.setStockQuantity(10); variant.setReservedQuantity(2);
        return variant;
    }

    @SuppressWarnings("unchecked")
    private static <T> T fake(Class<T> type, BiFunction<String, Object[], Object> handler) {
        return (T) Proxy.newProxyInstance(type.getClassLoader(), new Class<?>[]{type},
                (proxy, method, args) -> handler.apply(method.getName(), args));
    }
}
