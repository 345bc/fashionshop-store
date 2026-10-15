CREATE TABLE refresh_sessions (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    token_hash VARCHAR(64) NOT NULL,
    previous_token_hash VARCHAR(64) NULL,
    password_fingerprint VARCHAR(64) NOT NULL,
    created_at DATETIME2 NOT NULL,
    rotated_at DATETIME2 NOT NULL,
    expires_at DATETIME2 NOT NULL,
    revoked_at DATETIME2 NULL
);
CREATE UNIQUE INDEX ux_refresh_sessions_token ON refresh_sessions(token_hash);
CREATE INDEX ix_refresh_sessions_previous ON refresh_sessions(previous_token_hash);
CREATE INDEX ix_refresh_sessions_expiry ON refresh_sessions(expires_at);
