ALTER TABLE orders
    ADD recipient_email VARCHAR(254) NULL;

CREATE TABLE password_resets
(
    user_id      BIGINT      NOT NULL PRIMARY KEY REFERENCES users (id),
    token_hash   VARCHAR(64) NOT NULL,
    auth_version BIGINT      NOT NULL,
    created_at   DATETIME2   NOT NULL,
    expires_at   DATETIME2   NOT NULL
);
CREATE UNIQUE INDEX ux_password_resets_token ON password_resets (token_hash);

CREATE TABLE email_outbox
(
    id              BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    recipient       VARCHAR(254) NOT NULL,
    subject         NVARCHAR(255) NOT NULL,
    body            NVARCHAR(MAX) NOT NULL,
    attempts        INT          NOT NULL DEFAULT 0,
    next_attempt_at DATETIME2    NOT NULL,
    expires_at      DATETIME2 NULL
);
CREATE INDEX ix_email_outbox_pending ON email_outbox (next_attempt_at, attempts);
