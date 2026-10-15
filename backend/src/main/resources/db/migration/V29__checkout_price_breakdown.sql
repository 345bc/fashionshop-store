ALTER TABLE orders ADD shipping_discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    membership_discount_amount DECIMAL(18,2) NOT NULL DEFAULT 0,
    membership_discount_percent DECIMAL(5,2) NOT NULL DEFAULT 0;
