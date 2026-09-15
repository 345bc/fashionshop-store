-- ==========================================================
-- BỔ SUNG CÁC CỘT QUẢN LÝ HẠNG THÀNH VIÊN VÀ ĐIỂM THƯỞNG
-- ==========================================================

ALTER TABLE customer_profiles
    ADD
        -- Hạng thẻ: 'STANDARD', 'SILVER', 'GOLD', 'DIAMOND'
        membership_tier VARCHAR(20) NOT NULL CONSTRAINT df_customer_profiles_tier DEFAULT 'STANDARD',

    -- Điểm thưởng hiện có để đổi voucher/quà
    reward_points INT NOT NULL CONSTRAINT df_customer_profiles_points DEFAULT 0,

    -- Tổng tiền đã chi tiêu tích lũy (dùng để xét nâng hạng)
    total_spending DECIMAL(18,2) NOT NULL CONSTRAINT df_customer_profiles_spending DEFAULT 0.00,

    -- Ngày thăng hạng gần nhất
    tier_upgraded_at DATETIME NULL;

-- Thêm index để tối ưu việc lọc và thống kê theo hạng thành viên
CREATE INDEX idx_customer_profiles_tier ON customer_profiles (membership_tier);