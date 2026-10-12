ALTER TABLE promotion ADD target_mode VARCHAR(20) NOT NULL CONSTRAINT DF_promotion_target DEFAULT 'SELECTED';
GO
ALTER TABLE promotion ADD CONSTRAINT CK_promotion_target CHECK (target_mode IN ('SELECTED','NEW_PRODUCTS'));
GO
ALTER TABLE vouchers ADD name NVARCHAR(200) NULL;
GO
ALTER TABLE orders ADD original_subtotal DECIMAL(18,2) NOT NULL CONSTRAINT DF_orders_original_subtotal DEFAULT 0;
GO
UPDATE orders SET original_subtotal = subtotal;
GO
ALTER TABLE order_items ADD original_unit_price DECIMAL(18,2) NOT NULL CONSTRAINT DF_order_items_original_price DEFAULT 0;
GO
UPDATE order_items SET original_unit_price = unit_price;
GO

INSERT INTO promotion(name, description, discount_percent, startdate, enddate, is_active, target_mode)
VALUES (N'Ưu đãi sản phẩm mới', N'Tự động giảm 5% cho sản phẩm được tạo trong 7 ngày gần nhất.', 5,
        TODATETIMEOFFSET(SYSUTCDATETIME(), '+00:00'), '2099-01-01T00:00:00+00:00', 1, 'NEW_PRODUCTS');
GO
