-- Trạng thái nhân sự dùng trực tiếp users.is_active; không còn employment_status.
ALTER TABLE staff_profiles DROP CONSTRAINT df_staff_status;
ALTER TABLE staff_profiles DROP COLUMN employment_status;
