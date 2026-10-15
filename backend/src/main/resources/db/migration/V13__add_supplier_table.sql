ALTER TABLE suppliers
    ADD
        code VARCHAR(50) NULL,
    contact_person NVARCHAR(100) NULL,
    created_at DATETIMEOFFSET(7) NOT NULL
        CONSTRAINT DF_suppliers_created_at DEFAULT SYSDATETIMEOFFSET(),
    updated_at DATETIMEOFFSET(7) NOT NULL
        CONSTRAINT DF_suppliers_updated_at DEFAULT SYSDATETIMEOFFSET();