ALTER TABLE product_reviews ADD moderation_reason NVARCHAR(500) NULL;
CREATE TABLE review_history (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    review_id BIGINT NOT NULL,
    action NVARCHAR(100) NOT NULL,
    actor NVARCHAR(255) NOT NULL,
    note NVARCHAR(1000) NOT NULL,
    created_at DATETIME2 NOT NULL,
    CONSTRAINT fk_review_history_review FOREIGN KEY (review_id) REFERENCES product_reviews(id)
);
CREATE INDEX ix_review_history_review ON review_history(review_id, id);
