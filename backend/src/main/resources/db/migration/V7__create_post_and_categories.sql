-- 1. Danh mục bài viết (Blog Categories)
CREATE TABLE post_categories
(
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    name       NVARCHAR(100) NOT NULL,       -- vd: Xu hướng thời trang, Mẹo phối đồ, Khuyến mãi
    slug       VARCHAR(120) NOT NULL UNIQUE, -- vd: xu-huong-thoi-trang, meo-phoi-do
    is_active  BIT          NOT NULL DEFAULT 1,
    created_at datetimeoffset(7)             DEFAULT GETDATE()
);

-- 2. Bảng Bài viết (Posts)
CREATE TABLE post
(
    id           BIGINT IDENTITY(1,1) PRIMARY KEY,
    category_id  BIGINT          NOT NULL,
    author_id    BIGINT          NOT NULL,                 -- Nhân viên/Admin viết bài (trỏ users.id)

    title        NVARCHAR(255) NOT NULL,
    slug         VARCHAR(270) NOT NULL UNIQUE,          -- URL thân thiện SEO: cach-phoi-do-voi-ao-polo
    summary      NVARCHAR(500) NULL,                    -- Mô tả ngắn hiển thị ở thẻ tin tức
    thumbnail    VARCHAR(500) NOT NULL,                 -- Ảnh đại diện bài viết
    content      NVARCHAR(MAX) NOT NULL,                -- Nội dung bài viết (HTML từ Rich Text Editor / CKEditor)


    status       VARCHAR(20)  NOT NULL DEFAULT 'DRAFT', -- 'DRAFT' (Bản nháp), 'PUBLISHED' (Công khai), 'ARCHIVED' (Ẩn)
    view_count   INT          NOT NULL DEFAULT 0,       -- Lượt đọc bài

    published_at datetimeoffset(7) NULL,                        -- Thời điểm xuất bản (hỗ trợ hẹn giờ đăng)
    created_at   datetimeoffset(7)             DEFAULT GETDATE(),
    updated_at   datetimeoffset(7) NULL,

    CONSTRAINT fk_posts_category FOREIGN KEY (category_id) REFERENCES post_categories (id),
    CONSTRAINT fk_posts_author FOREIGN KEY (author_id) REFERENCES users (id)
);
