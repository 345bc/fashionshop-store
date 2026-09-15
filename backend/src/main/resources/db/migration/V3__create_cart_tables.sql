CREATE TABLE carts
(
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id    BIGINT NOT NULL UNIQUE,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE(),
    CONSTRAINT fk_carts_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE cart_items
(
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    cart_id    BIGINT NOT NULL,
    variant_id BIGINT NOT NULL,
    quantity   INT    NOT NULL DEFAULT 1 CHECK (quantity > 0),
    created_at DATETIME        DEFAULT GETDATE(),
    updated_at DATETIME        DEFAULT GETDATE(),
    CONSTRAINT fk_cart_items_cart FOREIGN KEY (cart_id) REFERENCES carts (id) ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_variant FOREIGN KEY (variant_id) REFERENCES product_variants (id),
    CONSTRAINT uq_cart_variant UNIQUE (cart_id, variant_id)
);