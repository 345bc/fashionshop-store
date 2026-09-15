CREATE TABLE chat_logs
(
    id              BIGINT IDENTITY(1,1) PRIMARY KEY,
    user_id         BIGINT NULL,
    user_message    NVARCHAR(MAX) NOT NULL,
    bot_response    NVARCHAR(MAX) NOT NULL,
    detected_intent VARCHAR(100) NULL,
    is_fallback     BIT NOT NULL DEFAULT 0,
    created_at      DATETIME     DEFAULT GETDATE(),
    CONSTRAINT fk_chat_logs_users FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE SET NULL
);