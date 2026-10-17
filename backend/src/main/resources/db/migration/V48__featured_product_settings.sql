CREATE TABLE featured_product_settings (
 id INT NOT NULL PRIMARY KEY,
 title NVARCHAR(200) NOT NULL,
 description NVARCHAR(500) NULL,
 window_days INT NOT NULL,
 purchase_weight INT NOT NULL,
 review_weight INT NOT NULL,
 is_display BIT NOT NULL,
 CONSTRAINT ck_featured_window CHECK(window_days BETWEEN 1 AND 365),
 CONSTRAINT ck_featured_weights CHECK(purchase_weight BETWEEN 0 AND 100 AND review_weight BETWEEN 0 AND 100 AND purchase_weight+review_weight=100)
);
INSERT INTO featured_product_settings VALUES(1,N'Sản phẩm nổi bật',N'Những thiết kế được khách hàng ưu tiên lựa chọn.',30,60,40,1);
