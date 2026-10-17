ALTER TABLE promotion ADD image_url VARCHAR(500) NULL, is_display BIT NOT NULL CONSTRAINT df_promotion_display DEFAULT 0;
ALTER TABLE vouchers ADD image_url VARCHAR(500) NULL, is_display BIT NOT NULL CONSTRAINT df_voucher_display DEFAULT 0;
