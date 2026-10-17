CREATE TABLE post_view_sessions (
    token VARCHAR(36) NOT NULL PRIMARY KEY,
    post_id BIGINT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    browser_id VARCHAR(36) NOT NULL,
    started_at DATETIMEOFFSET(7) NOT NULL,
    completed_at DATETIMEOFFSET(7) NULL
);
CREATE INDEX ix_post_view_sessions_started ON post_view_sessions(started_at);

CREATE TABLE post_view_readers (
    post_id BIGINT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    browser_id VARCHAR(36) NOT NULL,
    counted_at DATETIMEOFFSET(7) NOT NULL,
    PRIMARY KEY (post_id, browser_id)
);
CREATE INDEX ix_post_view_readers_counted ON post_view_readers(counted_at);
