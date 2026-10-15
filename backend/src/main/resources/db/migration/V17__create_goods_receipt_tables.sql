-- =====================================================
-- V17__create_goods_receipt_tables.sql
-- SQL Server
-- =====================================================

-- =====================================================
-- Goods Receipts
-- =====================================================

CREATE TABLE goods_receipts (
                                id BIGINT IDENTITY(1,1) PRIMARY KEY,

                                code VARCHAR(50) NOT NULL UNIQUE,

                                supplier_id BIGINT NOT NULL,

                                total_amount DECIMAL(18,2) NOT NULL DEFAULT 0,

                                payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID',

                                note NVARCHAR(500),

                                created_at DATETIMEOFFSET(7) NOT NULL
        DEFAULT SYSDATETIMEOFFSET(),

                                CONSTRAINT fk_goods_receipt_supplier
                                    FOREIGN KEY (supplier_id)
                                        REFERENCES suppliers(id)
);

-- =====================================================
-- Goods Receipt Items
-- =====================================================

CREATE TABLE goods_receipt_items (
                                     id BIGINT IDENTITY(1,1) PRIMARY KEY,

                                     receipt_id BIGINT NOT NULL,

                                     variant_id BIGINT NOT NULL,

                                     quantity INT NOT NULL,

                                     unit_cost DECIMAL(18,2) NOT NULL,

                                     subtotal AS (quantity * unit_cost),

                                     CONSTRAINT fk_goods_receipt_item_receipt
                                         FOREIGN KEY (receipt_id)
                                             REFERENCES goods_receipts(id)
                                             ON DELETE CASCADE,

                                     CONSTRAINT fk_goods_receipt_item_variant
                                         FOREIGN KEY (variant_id)
                                             REFERENCES product_variants(id)
);

-- =====================================================
-- Supplier Payments
-- =====================================================

CREATE TABLE supplier_payments (
                                   id BIGINT IDENTITY(1,1) PRIMARY KEY,

                                   receipt_id BIGINT NOT NULL,

                                   amount DECIMAL(18,2) NOT NULL,

                                   payment_method VARCHAR(30) NOT NULL,

                                   note NVARCHAR(500),

                                   paid_at DATETIMEOFFSET(7) NOT NULL
        DEFAULT SYSDATETIMEOFFSET(),

                                   CONSTRAINT fk_supplier_payment_receipt
                                       FOREIGN KEY (receipt_id)
                                           REFERENCES goods_receipts(id)
                                           ON DELETE CASCADE
);

-- =====================================================
-- Indexes
-- =====================================================

CREATE INDEX idx_goods_receipts_supplier_id
    ON goods_receipts(supplier_id);

CREATE INDEX idx_goods_receipt_items_receipt_id
    ON goods_receipt_items(receipt_id);

CREATE INDEX idx_goods_receipt_items_variant_id
    ON goods_receipt_items(variant_id);

CREATE INDEX idx_supplier_payments_receipt_id
    ON supplier_payments(receipt_id);