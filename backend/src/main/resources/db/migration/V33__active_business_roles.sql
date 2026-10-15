-- Canonical roles. Position remains a display field and never grants permissions.
INSERT INTO roles (role_code, role_name)
SELECT code, name FROM (VALUES
    ('ADMIN', N'Quản trị viên'), ('USER', N'Khách hàng'),
    ('SALES', N'Nhân viên bán hàng'), ('WAREHOUSE', N'Nhân viên kho'),
    ('CUSTOMER_SUPPORT', N'Chăm sóc khách hàng'), ('MARKETING', N'Nhân viên marketing')
) AS definitions(code, name)
WHERE NOT EXISTS (SELECT 1 FROM roles r WHERE r.role_code = definitions.code);

-- Preserve existing assignments without granting every business role to old employees.
INSERT INTO user_roles (user_id, role_id)
SELECT DISTINCT ur.user_id, target.id
FROM user_roles ur JOIN roles source ON source.id = ur.role_id
JOIN (VALUES ('EMPLOYEE', 'SALES'), ('CUSTOMER', 'USER'), ('ROLE_SUPER_ADMIN', 'ADMIN'),
    ('ROLE_WAREHOUSE', 'WAREHOUSE'), ('ROLE_CSKH', 'CUSTOMER_SUPPORT'),
    ('ROLE_MARKETING', 'MARKETING')) AS mapping(old_code, new_code) ON mapping.old_code = source.role_code
JOIN roles target ON target.role_code = mapping.new_code
WHERE NOT EXISTS (SELECT 1 FROM user_roles existing WHERE existing.user_id = ur.user_id AND existing.role_id = target.id);

DELETE FROM user_roles WHERE role_id IN (SELECT id FROM roles WHERE role_code IN
    ('EMPLOYEE', 'CUSTOMER', 'ROLE_SUPER_ADMIN', 'ROLE_WAREHOUSE', 'ROLE_CSKH', 'ROLE_MARKETING'));
DELETE FROM roles WHERE role_code IN
    ('EMPLOYEE', 'CUSTOMER', 'ROLE_SUPER_ADMIN', 'ROLE_WAREHOUSE', 'ROLE_CSKH', 'ROLE_MARKETING');

ALTER TABLE refresh_sessions ADD active_role VARCHAR(50) NULL;
-- Previous sessions did not select a role. Require a fresh login after migration.
UPDATE refresh_sessions SET revoked_at = SYSUTCDATETIME() WHERE revoked_at IS NULL;
