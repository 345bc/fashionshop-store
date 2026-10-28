CREATE TABLE bought_together_settings (
    id INT NOT NULL PRIMARY KEY,
    window_days INT NOT NULL,
    min_support DECIMAL(9,6) NOT NULL,
    min_cooccurrence INT NOT NULL,
    min_confidence DECIMAL(9,6) NOT NULL,
    min_lift DECIMAL(9,4) NOT NULL,
    max_recommendations INT NOT NULL,
    enabled BIT NOT NULL,
    CONSTRAINT ck_bought_together_singleton CHECK (id = 1),
    CONSTRAINT ck_bought_together_window CHECK (window_days BETWEEN 1 AND 365),
    CONSTRAINT ck_bought_together_support CHECK (min_support > 0 AND min_support <= 1),
    CONSTRAINT ck_bought_together_count CHECK (min_cooccurrence BETWEEN 1 AND 100000),
    CONSTRAINT ck_bought_together_confidence CHECK (min_confidence BETWEEN 0 AND 1),
    CONSTRAINT ck_bought_together_lift CHECK (min_lift BETWEEN 0 AND 100),
    CONSTRAINT ck_bought_together_limit CHECK (max_recommendations BETWEEN 1 AND 24)
);

INSERT INTO bought_together_settings
    (id, window_days, min_support, min_cooccurrence, min_confidence, min_lift, max_recommendations, enabled)
VALUES (1, 180, 0.01, 2, 0.1, 1, 8, 1);
