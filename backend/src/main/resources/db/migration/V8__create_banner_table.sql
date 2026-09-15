CREATE TABLE hero_banner
(
    id         BIGINT IDENTITY(1,1) NOT NULL,
    title      NVARCHAR(255) NOT NULL,
    subtitle   NVARCHAR(500) NULL,
    image_url  NVARCHAR(500) NOT NULL,
    is_active  BIT       NOT NULL CONSTRAINT DF_hero_banner_is_active DEFAULT 1,
    created_at DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_hero_banner_created_at DEFAULT SYSDATETIME(),
    updated_at DATETIMEOFFSET(7) NOT NULL CONSTRAINT DF_hero_banner_updated_at DEFAULT SYSDATETIME(),

    CONSTRAINT PK_hero_banner PRIMARY KEY (id)
);