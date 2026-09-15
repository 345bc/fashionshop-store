-- 1. Bảng Đánh giá sản phẩm
CREATE TABLE product_reviews
(
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    product_id    BIGINT     NOT NULL,
    customer_id   BIGINT   NOT NULL,           -- Trỏ tới customer_profiles(id)
    order_id      BIGINT  NOT NULL,           -- Bắt buộc: Đơn hàng đã mua
    order_item_id BIGINT  NOT NULL UNIQUE,    -- Chống đánh giá 2 lần cho cùng 1 món đã mua

    rating        TINYINT NOT NULL,           -- Số sao từ 1 đến 5
    comment       NVARCHAR(1000) NULL,        -- Nội dung đánh giá


    admin_reply   NVARCHAR(1000) NULL,        -- Phản hồi từ Shop/CSKH
    replied_at    DATETIMEOFFSET(7) NULL,

    is_hidden     BIT     NOT NULL DEFAULT 0, -- 1: Ẩn đánh giá vi phạm (chứa từ ngữ thô tục)
    created_at    DATETIMEOFFSET(7)        DEFAULT GETDATE(),
    updated_at    DATETIMEOFFSET(7) NULL,

    -- Ràng buộc
    CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_pr_product FOREIGN KEY (product_id) REFERENCES products (id),
    CONSTRAINT fk_pr_customer FOREIGN KEY (customer_id) REFERENCES customer_profiles (id),
    CONSTRAINT fk_pr_order FOREIGN KEY (order_id) REFERENCES orders (id),
    CONSTRAINT fk_pr_order_item FOREIGN KEY (order_item_id) REFERENCES order_items (id)
);
