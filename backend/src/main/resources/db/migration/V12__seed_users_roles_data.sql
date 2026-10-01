-- ============================================
-- DEMO DATA: ROLES
-- ============================================

INSERT INTO roles (role_code, role_name, description)
VALUES ('ADMIN', 'Quản trị viên', N'Có toàn quyền quản lý hệ thống'),
       ('EMPLOYEE', 'Nhân viên', N'Quản lý sản phẩm, đơn hàng và các nghiệp vụ được phân quyền'),
       ('CUSTOMER', 'Khách hàng', N'Khách hàng sử dụng hệ thống mua sắm');


-- ============================================
-- DEMO DATA: USERS
-- ============================================

INSERT INTO users
    (username, password_hash, email, is_active)
VALUES ('admin',
        '$2a$12$.aVrJkuaUiuA0rVG5XSVSeE8Ibz2KJQVUjj3gRavnrl3yR2u2oSN6',
        'admin@example.com',
        1),
       ('employee01',
        '$2a$12$.aVrJkuaUiuA0rVG5XSVSeE8Ibz2KJQVUjj3gRavnrl3yR2u2oSN6',
        'employee01@example.com',
        1),
       ('customer01',
        '$2a$12$.aVrJkuaUiuA0rVG5XSVSeE8Ibz2KJQVUjj3gRavnrl3yR2u2oSN6',
        'customer01@example.com',
        1),
       ('customer02',
        '$2a$12$.aVrJkuaUiuA0rVG5XSVSeE8Ibz2KJQVUjj3gRavnrl3yR2u2oSN6',
        'customer02@example.com',
        0);


-- ============================================
-- DEMO DATA: USER ROLES
-- ============================================

-- admin -> ADMIN
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
         CROSS JOIN roles r
WHERE u.email = 'admin@example.com'
  AND r.role_code = 'ADMIN';


-- employee01 -> EMPLOYEE
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
         CROSS JOIN roles r
WHERE u.email = 'employee01@example.com'
  AND r.role_code = 'EMPLOYEE';


-- customer01 -> CUSTOMER
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
         CROSS JOIN roles r
WHERE u.email = 'customer01@example.com'
  AND r.role_code = 'CUSTOMER';


-- customer02 -> CUSTOMER
INSERT INTO user_roles (user_id, role_id)
SELECT u.id, r.id
FROM users u
         CROSS JOIN roles r
WHERE u.email = 'customer02@example.com'
  AND r.role_code = 'CUSTOMER';