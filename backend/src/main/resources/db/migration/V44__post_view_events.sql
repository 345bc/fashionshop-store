CREATE TABLE post_view_events (
    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    post_id BIGINT NOT NULL REFERENCES post(id) ON DELETE CASCADE,
    counted_at DATETIMEOFFSET(7) NOT NULL
);
CREATE INDEX ix_post_view_events_time_post ON post_view_events(counted_at, post_id);
