-- Keep V39 unchanged once applied; align the audit timestamp with Java Instant.
ALTER TABLE review_history ALTER COLUMN created_at DATETIMEOFFSET(7) NOT NULL;
