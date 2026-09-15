-- =========================================================
-- 1. Bảng Danh mục
-- =========================================================
CREATE TABLE categories
(
    id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    parent_id BIGINT NULL,
    name      NVARCHAR(100) NOT NULL,
    slug      VARCHAR(120) NOT NULL UNIQUE,
    is_active BIT NOT NULL DEFAULT 1,

    CONSTRAINT fk_category_parent
        FOREIGN KEY (parent_id)
            REFERENCES categories (id)
);

-- =========================================================
-- 2. Bảng Nhà cung cấp
-- =========================================================
CREATE TABLE suppliers
(
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    name          NVARCHAR(150) NOT NULL,
    contact_email VARCHAR(100) NULL,
    phone         VARCHAR(20) NULL,
    address       NVARCHAR(255) NULL,
    is_active     BIT NOT NULL DEFAULT 1
);

-- =========================================================
-- 3. Bảng Size Guide
-- =========================================================
CREATE TABLE size_guides
(
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    name            NVARCHAR(100) NOT NULL,
    description     NVARCHAR(500) NULL,
    guide_image_url VARCHAR(500) NULL,
    is_active       BIT NOT NULL DEFAULT 1
);

-- =========================================================
-- 4. Bảng kích thước
-- =========================================================
CREATE TABLE size
(
    id            INT IDENTITY(1,1) PRIMARY KEY,
    name          VARCHAR(20) NOT NULL UNIQUE,
    display_order INT NOT NULL DEFAULT 0
);

-- =========================================================
-- 5. Bảng màu sắc
-- =========================================================
CREATE TABLE color
(
    id       INT IDENTITY(1,1) PRIMARY KEY,
    name     NVARCHAR(50) NOT NULL,
    hex_code VARCHAR(7) NULL,
    code     VARCHAR(10) NOT NULL UNIQUE
);

-- =========================================================
-- 6. Bảng Sản phẩm
-- =========================================================
CREATE TABLE products
(
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    category_id   BIGINT NOT NULL,
    supplier_id   BIGINT NULL,
    size_guide_id BIGINT NULL,

    name          NVARCHAR(200) NOT NULL,
    slug          VARCHAR(220) NOT NULL UNIQUE,
    description   NVARCHAR(MAX) NULL,

    style         VARCHAR(50) NULL,
    occasion      VARCHAR(100) NULL,

    base_price    DECIMAL(18, 2) NOT NULL,

    is_active     BIT NOT NULL DEFAULT 1,

    created_at    DATETIMEOFFSET(7) NOT NULL DEFAULT SYSDATETIME(),
    updated_at    DATETIMEOFFSET(7) NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT fk_product_category
        FOREIGN KEY (category_id)
            REFERENCES categories (id),

    CONSTRAINT fk_product_supplier
        FOREIGN KEY (supplier_id)
            REFERENCES suppliers (id)
            ON DELETE SET NULL,

    CONSTRAINT fk_product_size_guide
        FOREIGN KEY (size_guide_id)
            REFERENCES size_guides (id)
            ON DELETE SET NULL
);

-- =========================================================
-- 7. Bảng Ảnh Sản phẩm
-- =========================================================
CREATE TABLE product_images
(
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    product_id    BIGINT NOT NULL,
    image_url     VARCHAR(500) NOT NULL,
    is_primary    BIT NOT NULL DEFAULT 0,
    display_order INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_image_product
        FOREIGN KEY (product_id)
            REFERENCES products (id)
            ON DELETE CASCADE
);

-- =========================================================
-- 8. Bảng Biến thể sản phẩm
-- =========================================================
CREATE TABLE product_variants
(
    id                BIGINT IDENTITY(1,1) PRIMARY KEY,

    product_id        BIGINT NOT NULL,
    sku               VARCHAR(100) NOT NULL UNIQUE,

    size_id           INT NOT NULL,
    color_id          INT NOT NULL,

    price             DECIMAL(18, 2) NOT NULL,
    cost_price        DECIMAL(18, 2) NOT NULL DEFAULT 0,

    stock_quantity    INT NOT NULL DEFAULT 0,
    reserved_quantity INT NOT NULL DEFAULT 0,

    model_3d_url      VARCHAR(500) NULL,

    is_active         BIT NOT NULL DEFAULT 1,

    CONSTRAINT fk_variant_product
        FOREIGN KEY (product_id)
            REFERENCES products (id)
            ON DELETE CASCADE,

    CONSTRAINT fk_var_size
        FOREIGN KEY (size_id)
            REFERENCES size (id),

    CONSTRAINT fk_var_color
        FOREIGN KEY (color_id)
            REFERENCES color (id),

    CONSTRAINT uq_var_combo
        UNIQUE (product_id, size_id, color_id)
);

-- =========================================================
-- 9. Bảng Khuyến mãi
-- =========================================================
CREATE TABLE promotion
(
    id               BIGINT IDENTITY(1,1) NOT NULL,

    name             NVARCHAR(200) NOT NULL,
    description      NVARCHAR(500) NULL,

    discount_percent DECIMAL(5, 2) NOT NULL,

    startdate        DATETIMEOFFSET(7) NOT NULL,
    enddate          DATETIMEOFFSET(7) NOT NULL,

    is_active        BIT NOT NULL DEFAULT 0,

    created_at       DATETIMEOFFSET(7) NOT NULL DEFAULT SYSDATETIME(),
    updated_at       DATETIMEOFFSET(7) NULL,

    CONSTRAINT PK_Promotion
        PRIMARY KEY (id),

    CONSTRAINT CK_Promotion_DiscountPercent
        CHECK (discount_percent > 0
            AND discount_percent <= 100),

    CONSTRAINT CK_Promotion_Date
        CHECK (enddate > startdate)
);

-- =========================================================
-- 10. Quan hệ Promotion - Product
-- =========================================================
CREATE TABLE promotionproduct
(
    promotion_id BIGINT NOT NULL,
    product_id   BIGINT NOT NULL,

    CONSTRAINT PK_PromotionProduct
        PRIMARY KEY (product_id, promotion_id),

    CONSTRAINT FK_PromotionProduct_Promotion
        FOREIGN KEY (promotion_id)
            REFERENCES promotion (id),

    CONSTRAINT FK_PromotionProduct_Product
        FOREIGN KEY (product_id)
            REFERENCES products (id)
);

-- -- =========================================================
-- -- INDEX
-- -- =========================================================
--
-- CREATE INDEX idx_products_category
--     ON products(category_id);
--
-- CREATE INDEX idx_products_style
--     ON products(style);
--
-- CREATE INDEX idx_variants_product
--     ON product_variants(product_id);
--
-- CREATE INDEX idx_product_images_product
--     ON product_images(product_id);
--
-- CREATE INDEX idx_promotionproduct_product
--     ON promotionproduct(product_id);
--
-- CREATE INDEX idx_promotionproduct_promotion
--     ON promotionproduct(promotion_id);