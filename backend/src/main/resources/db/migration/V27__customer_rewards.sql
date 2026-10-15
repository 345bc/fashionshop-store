ALTER TABLE orders ALTER COLUMN points_earned DECIMAL(18,2) NOT NULL;
GO
ALTER TABLE vouchers ADD owner_customer_id BIGINT NULL REFERENCES customer_profiles(id),
    redemption_key VARCHAR(36) NULL;
GO
CREATE UNIQUE INDEX ux_voucher_redemption ON vouchers(redemption_key) WHERE redemption_key IS NOT NULL;
CREATE TABLE reward_transactions (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_id BIGINT NOT NULL REFERENCES customer_profiles(id),
    points INT NOT NULL,
    balance_after INT NOT NULL,
    description NVARCHAR(300) NOT NULL,
    reference_key VARCHAR(100) NOT NULL UNIQUE,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE INDEX ix_rewards_customer_date ON reward_transactions(customer_id, created_at DESC, id DESC);
CREATE INDEX ix_order_customer_status ON orders(user_id, order_status, id DESC);
GO
INSERT INTO vouchers(code,description,discount_type,discount_value,discount_amount,min_order_amount,usage_limit,used_count,is_active,start_date,end_date,points_required,is_redeemable)
SELECT reward.code,reward.description,reward.kind,reward.amount,reward.cap,reward.minimum,NULL,0,1,SYSUTCDATETIME(),'2099-12-31',reward.points,1
FROM (VALUES
 ('REWARD-20',N'Voucher 20.000đ','FIXED',20000,20000,200000,200),
 ('REWARD-50',N'Voucher 50.000đ','FIXED',50000,50000,400000,500),
 ('REWARD-100',N'Voucher 100.000đ','FIXED',100000,100000,700000,1000),
 ('REWARD-10P',N'Giảm 10%','PERCENT',10,80000,0,800),
 ('REWARD-GIFT',N'Gói quà và thiệp','GIFT',0,0,0,150)
) reward(code,description,kind,amount,cap,minimum,points)
WHERE NOT EXISTS (SELECT 1 FROM vouchers WHERE code=reward.code);
