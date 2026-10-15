ALTER TABLE users ADD auth_version BIGINT NOT NULL CONSTRAINT df_users_auth_version DEFAULT 0;
ALTER TABLE refresh_sessions ADD role_selection_required BIT NOT NULL CONSTRAINT df_refresh_role_selection DEFAULT 0;
ALTER TABLE staff_profiles ADD phone VARCHAR(20) NULL, employment_status VARCHAR(20) NOT NULL CONSTRAINT df_staff_status DEFAULT 'ACTIVE';
CREATE TABLE staff_audit (
 id BIGINT IDENTITY(1,1) PRIMARY KEY,
 staff_id BIGINT NOT NULL,
 actor_id BIGINT NOT NULL,
 action VARCHAR(50) NOT NULL,
 details NVARCHAR(2000) NOT NULL,
 created_at datetimeoffset(7) NOT NULL DEFAULT SYSDATETIMEOFFSET(),
 CONSTRAINT fk_staff_audit_profile FOREIGN KEY(staff_id) REFERENCES staff_profiles(id),
 CONSTRAINT fk_staff_audit_actor FOREIGN KEY(actor_id) REFERENCES users(id)
);
UPDATE refresh_sessions SET revoked_at = SYSDATETIME() WHERE revoked_at IS NULL;
