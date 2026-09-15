-- ==========================================================
-- RETURN / EXCHANGE MANAGEMENT
-- ==========================================================

-- ==========================================================
-- 1. RETURN REQUESTS
-- ==========================================================
CREATE TABLE return_requests
(
    id BIGINT IDENTITY(1,1) PRIMARY KEY,

    request_code VARCHAR(32) NOT NULL UNIQUE,

    order_id BIGINT NOT NULL,

    user_id BIGINT NOT NULL,

    request_type VARCHAR(20) NOT NULL DEFAULT 'RETURN',
    -- RETURN | EXCHANGE

    reason_code VARCHAR(50) NOT NULL,

    customer_note NVARCHAR(500) NULL,

    admin_note NVARCHAR(500) NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    -- PENDING
    -- APPROVED
    -- REJECTED
    -- RETURNING
    -- RECEIVED
    -- COMPLETED
    -- CANCELLED

    refund_amount DECIMAL(18,2) NULL,

    refund_method VARCHAR(30) NULL,
    -- WALLET
    -- BANK_TRANSFER
    -- ORIGINAL_PAYMENT

    tracking_number VARCHAR(100) NULL,

    shipping_provider VARCHAR(50) NULL,

    approved_at DATETIME NULL,

    rejected_at DATETIME NULL,

    received_at DATETIME NULL,

    completed_at DATETIME NULL,

    cancelled_at DATETIME NULL,

    created_at DATETIME NOT NULL DEFAULT GETDATE(),

    updated_at DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT fk_return_requests_order
        FOREIGN KEY (order_id)
            REFERENCES orders(id),

    CONSTRAINT fk_return_requests_user
        FOREIGN KEY (user_id)
            REFERENCES users(id)
);

-- ==========================================================
-- 2. RETURN ITEMS
-- ==========================================================
CREATE TABLE return_items
(
    id BIGINT IDENTITY(1,1) PRIMARY KEY,

    return_request_id BIGINT NOT NULL,

    order_item_id BIGINT NOT NULL,

    quantity INT NOT NULL,

    exchange_variant_id BIGINT NULL,

    item_condition VARCHAR(50) NULL,
    -- INTACT
    -- DAMAGED

    created_at DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT chk_return_item_quantity
        CHECK (quantity > 0),

    CONSTRAINT fk_return_items_request
        FOREIGN KEY (return_request_id)
            REFERENCES return_requests(id)
            ON DELETE CASCADE,

    CONSTRAINT fk_return_items_order_item
        FOREIGN KEY (order_item_id)
            REFERENCES order_items(id),

    CONSTRAINT fk_return_items_exchange_variant
        FOREIGN KEY (exchange_variant_id)
            REFERENCES product_variants(id)
);

-- ==========================================================
-- 3. EVIDENCE FILES
-- ==========================================================
CREATE TABLE return_evidences
(
    id BIGINT IDENTITY(1,1) PRIMARY KEY,

    return_request_id BIGINT NOT NULL,

    file_url NVARCHAR(500) NOT NULL,

    file_type VARCHAR(20) NOT NULL,
    -- IMAGE
    -- VIDEO

    created_at DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT fk_return_evidences_request
        FOREIGN KEY (return_request_id)
            REFERENCES return_requests(id)
            ON DELETE CASCADE
);

-- ==========================================================
-- 4. STATUS HISTORY
-- ==========================================================
CREATE TABLE return_request_histories
(
    id BIGINT IDENTITY(1,1) PRIMARY KEY,

    return_request_id BIGINT NOT NULL,

    old_status VARCHAR(30) NULL,

    new_status VARCHAR(30) NOT NULL,

    changed_by BIGINT NOT NULL,

    note NVARCHAR(500) NULL,

    created_at DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT fk_return_histories_request
        FOREIGN KEY (return_request_id)
            REFERENCES return_requests(id)
            ON DELETE CASCADE,

    CONSTRAINT fk_return_histories_user
        FOREIGN KEY (changed_by)
            REFERENCES users(id)
);

-- ==========================================================
-- INDEXES
-- ==========================================================

CREATE INDEX idx_return_requests_code
    ON return_requests(request_code);

CREATE INDEX idx_return_requests_order_id
    ON return_requests(order_id);

CREATE INDEX idx_return_requests_user_id
    ON return_requests(user_id);

CREATE INDEX idx_return_requests_status
    ON return_requests(status);

CREATE INDEX idx_return_items_request_id
    ON return_items(return_request_id);

CREATE INDEX idx_return_evidences_request_id
    ON return_evidences(return_request_id);

CREATE INDEX idx_return_histories_request_id
    ON return_request_histories(return_request_id);

CREATE INDEX idx_return_histories_created_at
    ON return_request_histories(created_at);