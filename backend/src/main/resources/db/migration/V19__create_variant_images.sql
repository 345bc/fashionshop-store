CREATE TABLE variant_images
(
    id            BIGINT IDENTITY(1,1) PRIMARY KEY,
    variant_id    BIGINT NOT NULL,
    image_url     VARCHAR(500) NOT NULL,
    is_primary    BIT NOT NULL DEFAULT 0,
    display_order INT NOT NULL DEFAULT 0,

    CONSTRAINT fk_variant_image_variant
        FOREIGN KEY (variant_id)
            REFERENCES product_variants (id)
            ON DELETE CASCADE
);

CREATE INDEX idx_variant_images_variant_order
    ON variant_images (variant_id, display_order, id);
