CREATE TABLE new_product_showcase (
    id INT NOT NULL PRIMARY KEY,
    title NVARCHAR(200) NOT NULL,
    description NVARCHAR(500) NULL,
    image_url VARCHAR(500) NULL
);
-- Preserve existing editorial assets; discount eligibility no longer depends on this legacy promotion.
INSERT INTO new_product_showcase (id,title,description,image_url)
SELECT TOP (1) 1,name,description,image_url FROM promotion
WHERE target_mode='NEW_PRODUCTS'
ORDER BY CASE WHEN image_url IS NOT NULL AND LEN(image_url)>0 THEN 0 ELSE 1 END,id;
IF NOT EXISTS (SELECT 1 FROM new_product_showcase)
    INSERT INTO new_product_showcase(id,title,description)
    VALUES(1,N'Ưu đãi sản phẩm mới',N'Khám phá thiết kế mới với ưu đãi 5% trong 7 ngày đầu.');
