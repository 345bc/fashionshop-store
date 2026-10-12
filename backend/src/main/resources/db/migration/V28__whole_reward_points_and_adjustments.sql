ALTER TABLE orders ALTER COLUMN points_earned INT NOT NULL;
ALTER TABLE customer_profiles ADD reward_point_adjustment INT NOT NULL DEFAULT 0;
GO
UPDATE customer_profiles SET reward_point_adjustment=-reward_points, reward_points=0 WHERE reward_points<0;
ALTER TABLE customer_profiles ADD CONSTRAINT chk_customer_points_nonnegative CHECK(reward_points>=0 AND reward_point_adjustment>=0);
UPDATE vouchers SET is_redeemable=0 WHERE is_redeemable IS NULL;
UPDATE vouchers SET used_count=0 WHERE used_count IS NULL;
