ALTER TABLE orders
    ADD inventory_managed BIT NOT NULL CONSTRAINT df_order_inventory_managed DEFAULT 0;
GO
ALTER TABLE order_items ALTER COLUMN sku VARCHAR(100) NOT NULL;
GO
ALTER TABLE order_items
    ADD unit_cost DECIMAL(18, 2) NOT NULL CONSTRAINT df_order_item_cost DEFAULT 0;
GO
ALTER TABLE inventory_movements
    ADD before_reserved INT NULL, after_reserved INT NULL;
GO
CREATE TABLE order_histories
(
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id   BIGINT      NOT NULL REFERENCES orders (id),
    old_status VARCHAR(30) NULL,
    new_status VARCHAR(30) NOT NULL,
    note       NVARCHAR(500) NULL,
    created_by BIGINT      NOT NULL REFERENCES users (id),
    created_at DATETIME2   NOT NULL DEFAULT SYSUTCDATETIME()
);
GO
ALTER TABLE return_items
    ADD unit_cost DECIMAL(18, 2) NOT NULL CONSTRAINT df_return_item_cost DEFAULT 0;
GO
ALTER TABLE goods_receipts
    ADD returned_amount DECIMAL(18, 2) NOT NULL CONSTRAINT df_receipt_returned DEFAULT 0,
 supplier_refunded_amount DECIMAL(18,2) NOT NULL CONSTRAINT df_receipt_refunded DEFAULT 0;
GO
CREATE TABLE supplier_returns
(
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    code       VARCHAR(50)    NOT NULL UNIQUE,
    receipt_id BIGINT         NOT NULL REFERENCES goods_receipts (id),
    reason     NVARCHAR(500) NOT NULL,
    amount     DECIMAL(18, 2) NOT NULL,
    created_by BIGINT         NOT NULL REFERENCES users (id),
    created_at DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO
CREATE TABLE supplier_return_items
(
    id                 BIGINT IDENTITY(1,1) PRIMARY KEY,
    supplier_return_id BIGINT         NOT NULL REFERENCES supplier_returns (id),
    variant_id         BIGINT         NOT NULL REFERENCES product_variants (id),
    quantity           INT            NOT NULL CHECK (quantity > 0),
    unit_cost          DECIMAL(18, 2) NOT NULL,
    CONSTRAINT uq_supplier_return_variant UNIQUE (supplier_return_id, variant_id)
);
GO
CREATE TABLE supplier_refunds
(
    id             BIGINT IDENTITY(1,1) PRIMARY KEY,
    receipt_id     BIGINT         NOT NULL REFERENCES goods_receipts (id),
    amount         DECIMAL(18, 2) NOT NULL CHECK (amount > 0),
    payment_method VARCHAR(30)    NOT NULL,
    note           NVARCHAR(500) NULL,
    created_by     BIGINT         NOT NULL REFERENCES users (id),
    created_at     DATETIMEOFFSET NOT NULL DEFAULT SYSDATETIMEOFFSET()
);
GO
CREATE INDEX idx_order_history_order ON order_histories (order_id, id);
GO
CREATE INDEX idx_supplier_return_receipt ON supplier_returns (receipt_id);
GO

