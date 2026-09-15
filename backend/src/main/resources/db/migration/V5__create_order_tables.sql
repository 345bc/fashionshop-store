CREATE TABLE orders
(
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_code      VARCHAR(32)    NOT NULL UNIQUE,
    user_id         BIGINT         NOT NULL,
    voucher_id      BIGINT NULL,
    recipient_name  NVARCHAR(150) NOT NULL,
    recipient_phone VARCHAR(20)    NOT NULL,
    recipient_note  NVARCHAR(500) NULL,
    address         NVARCHAR(350) NOT NULL,
    subtotal        DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    shipping_fee    DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    discount_amount DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    total_amount    DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    payment_method  VARCHAR(30)    NOT NULL,
    payment_status  VARCHAR(20)    NOT NULL DEFAULT 'PENDING',
    order_status    VARCHAR(30)    NOT NULL DEFAULT 'PENDING',
    points_earned   DECIMAL(5, 1)  NOT NULL,
    created_at      DATETIME                DEFAULT GETDATE(),
    updated_at      DATETIME                DEFAULT GETDATE(),
    CONSTRAINT fk_orders_users FOREIGN KEY (user_id) REFERENCES users (id),
    CONSTRAINT fk_orders_vouchers FOREIGN KEY (voucher_id) REFERENCES vouchers (id)
);

CREATE TABLE order_items
(
    id           BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id     BIGINT         NOT NULL,
    variant_id   BIGINT         NOT NULL,
    product_id   BIGINT         NOT NULL,
    product_name NVARCHAR(200) NOT NULL,  -- Tên sản phẩm lúc mua (phòng trường hợp sau này shop đổi tên)
    sku          VARCHAR(50)    NOT NULL, -- Mã SKU tại thời điểm mua
    unit_price   DECIMAL(18, 2) NOT NULL,
    quantity     INT            NOT NULL CHECK (quantity > 0),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_variant FOREIGN KEY (variant_id) REFERENCES product_variants (id),
    CONSTRAINT fk_items_products FOREIGN KEY (product_id) REFERENCES products (id)
);