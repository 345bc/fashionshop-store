CREATE TABLE payment_refunds (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    order_id BIGINT NOT NULL REFERENCES orders(id),
    return_id BIGINT NULL REFERENCES return_requests(id),
    request_id VARCHAR(32) NOT NULL UNIQUE,
    target VARCHAR(60) NOT NULL,
    amount DECIMAL(18,2) NOT NULL CHECK (amount > 0),
    state VARCHAR(20) NOT NULL,
    merchant_code VARCHAR(8) NOT NULL,
    transaction_type VARCHAR(2) NOT NULL,
    transaction_date VARCHAR(14) NOT NULL,
    transaction_no VARCHAR(20) NOT NULL,
    refund_transaction_no VARCHAR(20) NULL,
    response_code VARCHAR(10) NULL,
    gateway_status VARCHAR(10) NULL,
    note NVARCHAR(400) NOT NULL,
    actor_id BIGINT NOT NULL REFERENCES users(id),
    created_at DATETIME2 NOT NULL,
    updated_at DATETIME2 NOT NULL
);
CREATE INDEX ix_payment_refunds_order ON payment_refunds(order_id, id);
CREATE INDEX ix_payment_refunds_target ON payment_refunds(target, id);
