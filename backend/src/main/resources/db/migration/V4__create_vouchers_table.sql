CREATE TABLE vouchers
(
    id               BIGINT IDENTITY(1,1) PRIMARY KEY,
    code             VARCHAR(50)    NOT NULL UNIQUE,
    description      NVARCHAR(500) NOT NULL,
    discount_type    VARCHAR(20)    NOT NULL,
    discount_value   DECIMAL(18, 2) NOT NULL,
    discount_amount  DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    min_order_amount DECIMAL(18, 2) NOT NULL DEFAULT 0.00,
    usage_limit      INT,
    used_count       INT,
    is_active        BIT            NOT NULL DEFAULT 1,
    start_date       DATETIME       NOT NULL,
    end_date         DATETIME       NOT NULL,
    created_at       DATETIME                DEFAULT GETDATE(),
    points_required  INT NULL,
    is_redeemable    BIT,
);