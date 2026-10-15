INSERT INTO suppliers (
    name,
    contact_email,
    phone,
    address,
    is_active,
    code,
    contact_person,
    created_at,
    updated_at
)
VALUES
    (
        N'Công ty TNHH Thời Trang ABC',
        N'contact@abcfashion.vn',
        '0901234567',
        N'Quận 1, TP. Hồ Chí Minh',
        1,
        N'NCC001',
        N'Nguyễn Văn An',
        SYSDATETIMEOFFSET(),
        SYSDATETIMEOFFSET()
    ),
    (
        N'Công ty TNHH Dệt May Việt Tiến',
        N'sales@viettien-fashion.vn',
        '0902345678',
        N'Quận Tân Bình, TP. Hồ Chí Minh',
        1,
        N'NCC002',
        N'Trần Minh Đức',
        SYSDATETIMEOFFSET(),
        SYSDATETIMEOFFSET()
    ),
    (
        N'Công ty TNHH May Mặc Minh Long',
        N'info@minhlongfashion.vn',
        '0903456789',
        N'Quận Bình Thạnh, TP. Hồ Chí Minh',
        1,
        N'NCC003',
        N'Lê Thị Mai',
        SYSDATETIMEOFFSET(),
        SYSDATETIMEOFFSET()
    ),
    (
        N'Công ty TNHH Fashion House',
        N'contact@fashionhouse.vn',
        '0904567890',
        N'Thành phố Thủ Đức, TP. Hồ Chí Minh',
        1,
        N'NCC004',
        N'Phạm Quốc Huy',
        SYSDATETIMEOFFSET(),
        SYSDATETIMEOFFSET()
    ),
    (
        N'Công ty TNHH Global Garment',
        N'sales@globalgarment.vn',
        '0905678901',
        N'Quận 7, TP. Hồ Chí Minh',
        1,
        N'NCC005',
        N'Võ Thanh Tùng',
        SYSDATETIMEOFFSET(),
        SYSDATETIMEOFFSET()
    );