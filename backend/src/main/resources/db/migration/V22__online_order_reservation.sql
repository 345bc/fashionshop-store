ALTER TABLE orders ALTER COLUMN user_id BIGINT NULL;
GO
ALTER TABLE return_requests ALTER COLUMN user_id BIGINT NULL;
GO
ALTER TABLE order_histories ALTER COLUMN created_by BIGINT NULL;
GO
ALTER TABLE orders ADD payment_expires_at DATETIME2 NULL,
    online_transaction_id VARCHAR(100) NULL,
    checkout_token_hash VARCHAR(64) NULL;
GO
UPDATE orders SET payment_method = 'ONLINE', order_status = 'PENDING',
    payment_expires_at = DATEADD(MINUTE, 5, created_at)
WHERE inventory_managed = 1 AND payment_status = 'PENDING' AND order_status IN ('PENDING', 'CONFIRMED');
GO
CREATE UNIQUE INDEX uq_order_online_transaction ON orders(online_transaction_id)
WHERE online_transaction_id IS NOT NULL;
GO
CREATE INDEX idx_order_payment_expiration ON orders(order_status, payment_status, payment_expires_at);
GO

