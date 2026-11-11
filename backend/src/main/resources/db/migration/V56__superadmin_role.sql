-- Require an explicit first grant instead of upgrading an existing custom assignment.
IF EXISTS (SELECT 1 FROM user_roles ur JOIN roles r ON r.id = ur.role_id WHERE UPPER(r.role_code) = 'SUPERADMIN')
    THROW 51000, 'Remove existing custom SUPERADMIN assignments before enabling the built-in role.', 1;

IF EXISTS (SELECT 1 FROM roles WHERE UPPER(role_code) = 'SUPERADMIN')
    UPDATE roles SET role_code = 'SUPERADMIN', role_name = N'Quản trị viên cấp cao',
        description = N'Toàn quyền nghiệp vụ quản trị' WHERE UPPER(role_code) = 'SUPERADMIN';
ELSE
    INSERT INTO roles (role_code, role_name, description)
    VALUES ('SUPERADMIN', N'Quản trị viên cấp cao', N'Toàn quyền nghiệp vụ quản trị');
