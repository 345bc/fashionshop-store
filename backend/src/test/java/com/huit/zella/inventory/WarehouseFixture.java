package com.huit.zella.inventory;
import com.huit.zella.auth.User;
import com.huit.zella.category.Category;
import com.huit.zella.color.Color;
import com.huit.zella.common.exception.BusinessException;


import com.huit.zella.product.Product;
import com.huit.zella.productvariant.ProductVariant;
import com.huit.zella.size.Size;
import com.huit.zella.sizeguide.SizeGuide;
import com.huit.zella.supplier.Supplier;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.junit.jupiter.api.BeforeEach;


import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;

import java.util.UUID;


public abstract class WarehouseFixture {
    @PersistenceContext protected EntityManager em;
    protected User actor;
    protected Supplier supplier;
    protected ProductVariant variant;

    @BeforeEach
    protected void fixture() {
        String token = UUID.randomUUID().toString().substring(0, 8);
        actor = new User(); actor.setUserName("test-" + token);
        actor.setEmail(token + "@warehouse.test"); actor.setPasswordHash("test-only");
        em.persist(actor);
        com.huit.zella.customer.Customer customer = new com.huit.zella.customer.Customer();
        customer.setFullName("Warehouse test customer");
        actor.setProfile(customer);
        em.persist(customer);
        supplier = new Supplier(); supplier.setName("Warehouse test " + token); em.persist(supplier);
        Category category = new Category(); category.setName("Test"); category.setSlug("test-" + token); em.persist(category);
        SizeGuide guide = new SizeGuide(); guide.setName("Test"); em.persist(guide);
        Size size = em.createQuery("select s from Size s", Size.class).setMaxResults(1)
            .getResultStream().findFirst().orElseGet(() -> { Size s = new Size(); s.setName("M"); em.persist(s); return s; });
        Color color = new Color(); color.setName("Test"); color.setCode(token); em.persist(color);
        Product product = new Product(); product.setName("Test product"); product.setSlug("test-" + token);
        product.setCategory(category); product.setSupplier(supplier); product.setSizeGuide(guide); product.setBasePrice(new BigDecimal("300"));
        em.persist(product);
        variant = new ProductVariant(); variant.setProduct(product); variant.setSku("TEST-" + token);
        variant.setSize(size); variant.setColor(color); variant.setPrice(new BigDecimal("300"));
        variant.setCostPrice(new BigDecimal("100")); variant.setStockQuantity(10); variant.setReservedQuantity(2);
        em.persist(variant); em.flush();
    }
}
