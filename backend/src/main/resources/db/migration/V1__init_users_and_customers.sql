-- 1. Bảng tài khoản nhân viên / quản trị viên
CREATE TABLE users
(
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email         VARCHAR(100) NOT NULL UNIQUE,
    is_active     BIT          NOT NULL DEFAULT 1,
    created_at    datetimeoffset(7)    NOT NULL DEFAULT GETDATE(),
    updated_at    datetimeoffset(7)    NOT NULL DEFAULT GETDATE()
);
-- 2. Bảng Vai trò (Roles)
CREATE TABLE roles
(
    id          BIGINT IDENTITY(1,1) PRIMARY KEY,
    role_code   VARCHAR(50) NOT NULL UNIQUE,
    role_name   NVARCHAR(100) NOT NULL,
    description NVARCHAR(255) NULL
);

-- 3. Bảng Phân quyền Người dùng - Vai trò (User Roles - Mối quan hệ N-N)
CREATE TABLE user_roles
(
    user_id     BIGINT    NOT NULL,
    role_id     BIGINT    NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_ur_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT fk_ur_role FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE
);

-- 4. Bảng Nhân viên nội bộ (Staff / Employee Profiles)
CREATE TABLE staff_profiles
(
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id    BIGINT      NOT NULL UNIQUE,
    staff_code VARCHAR(20) NOT NULL UNIQUE,
    full_name  NVARCHAR(100) NOT NULL,
    position   NVARCHAR(100) NULL,
    hired_date DATE        NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    salary     DECIMAL(18, 2) NULL,
    CONSTRAINT fk_staff_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
);

-- 5. Bảng Hồ sơ Khách hàng (Customer Profiles - Kèm thông số vóc dáng cho AI)
CREATE TABLE customer_profiles
(
    id         BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id    BIGINT NULL UNIQUE,
    full_name  NVARCHAR(100) NOT NULL,
    phone      VARCHAR(20) NULL,
    address    NVARCHAR(255) NULL,
    created_at datetimeoffset(7)    NOT NULL DEFAULT GETDATE(),
    updated_at datetimeoffset(7)    NOT NULL DEFAULT GETDATE(),
    CONSTRAINT fk_customer_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
);

-- Dữ liệu hạt giống (Seed Data) ban đầu cho hệ thống
INSERT INTO roles (role_code, role_name, description)
VALUES ('ROLE_SUPER_ADMIN', N'Quản trị viên cấp cao', N'Toàn quyền quản trị hệ sinh thái'),
       ('ROLE_WAREHOUSE', N'Thủ kho', N'Quản lý kiểm kê, nhập xuất kho sản phẩm'),
       ('ROLE_CSKH', N'Chăm sóc khách hàng', N'Xem lịch sử chat AI, phản hồi hỗ trợ và xử lý hoàn tiền'),
       ('ROLE_MARKETING', N'Marketing / Content', N'Đăng tải bài viết blog, quản lý xu hướng phong cách');

-- CREATE INDEX idx_users_username ON users(username);
-- CREATE INDEX idx_users_email ON users(email);
-- CREATE INDEX idx_customer_email ON customer_profiles(email);
-- CREATE INDEX idx_staff_code ON staff_profiles(staff_code);