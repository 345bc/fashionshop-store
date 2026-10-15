ALTER TABLE goods_receipts ADD
    status VARCHAR(20) NOT NULL CONSTRAINT df_receipt_status DEFAULT 'POSTED',
    posted_at DATETIMEOFFSET(7) NULL,
    cancelled_at DATETIMEOFFSET(7) NULL,
    created_by BIGINT NULL,
    posted_by BIGINT NULL,
    cancelled_by BIGINT NULL;
GO
UPDATE goods_receipts SET posted_at = created_at WHERE status = 'POSTED';
GO
ALTER TABLE goods_receipts ADD CONSTRAINT fk_receipt_created_by FOREIGN KEY(created_by) REFERENCES users(id);
GO
ALTER TABLE goods_receipts ADD CONSTRAINT fk_receipt_posted_by FOREIGN KEY(posted_by) REFERENCES users(id);
GO
ALTER TABLE goods_receipts ADD CONSTRAINT fk_receipt_cancelled_by FOREIGN KEY(cancelled_by) REFERENCES users(id);
GO
ALTER TABLE supplier_payments ADD created_by BIGINT NULL;
GO
ALTER TABLE goods_receipt_items ADD before_unit_cost DECIMAL(18,2) NULL;
GO
ALTER TABLE goods_receipt_items ADD sku_snapshot VARCHAR(100) NULL,
    product_name_snapshot NVARCHAR(200) NULL, size_name_snapshot VARCHAR(20) NULL, color_name_snapshot NVARCHAR(50) NULL;
GO
UPDATE i SET sku_snapshot = v.sku, product_name_snapshot = p.name, size_name_snapshot = s.name, color_name_snapshot = c.name
FROM goods_receipt_items i JOIN product_variants v ON v.id = i.variant_id
JOIN products p ON p.id = v.product_id JOIN size s ON s.id = v.size_id JOIN color c ON c.id = v.color_id;
GO
ALTER TABLE supplier_payments ADD CONSTRAINT fk_supplier_payment_actor FOREIGN KEY(created_by) REFERENCES users(id);
GO
CREATE TABLE inventory_adjustments (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    reason NVARCHAR(500) NOT NULL,
    created_at DATETIMEOFFSET(7) NOT NULL,
    created_by BIGINT NOT NULL REFERENCES users(id)
);
GO
CREATE TABLE inventory_adjustment_items (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    adjustment_id BIGINT NOT NULL REFERENCES inventory_adjustments(id),
    variant_id BIGINT NOT NULL REFERENCES product_variants(id),
    before_quantity INT NOT NULL,
    counted_quantity INT NOT NULL,
    CONSTRAINT chk_adjustment_count CHECK(counted_quantity >= 0),
    CONSTRAINT uq_adjustment_variant UNIQUE(adjustment_id, variant_id)
);
GO
CREATE TABLE inventory_movements (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    variant_id BIGINT NOT NULL REFERENCES product_variants(id),
    movement_type VARCHAR(30) NOT NULL,
    quantity_change INT NOT NULL,
    before_quantity INT NOT NULL,
    after_quantity INT NOT NULL,
    reference_code VARCHAR(50) NOT NULL,
    reason NVARCHAR(500) NULL,
    created_at DATETIMEOFFSET(7) NOT NULL,
    created_by BIGINT NULL REFERENCES users(id)
);
GO
CREATE INDEX idx_movement_variant ON inventory_movements(variant_id, id);
GO
INSERT INTO inventory_movements(variant_id, movement_type, quantity_change, before_quantity, after_quantity, reference_code, reason, created_at)
SELECT id, 'OPENING', stock_quantity, 0, stock_quantity, 'OPENING', N'Tồn kho trước khi triển khai lịch sử kho', SYSDATETIMEOFFSET()
FROM product_variants WHERE stock_quantity <> 0;
GO
ALTER TABLE product_variants ADD CONSTRAINT chk_inventory_quantities
    CHECK(stock_quantity >= 0 AND reserved_quantity >= 0 AND reserved_quantity <= stock_quantity);
GO
ALTER TABLE goods_receipt_items ADD CONSTRAINT chk_receipt_item_quantity CHECK(quantity > 0);
GO
ALTER TABLE goods_receipt_items ADD CONSTRAINT chk_receipt_item_cost CHECK(unit_cost >= 0);
GO
ALTER TABLE supplier_payments ADD CONSTRAINT chk_supplier_payment_amount CHECK(amount > 0);
GO
