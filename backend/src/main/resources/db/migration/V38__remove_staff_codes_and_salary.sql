-- Remove constraints before dropping the obsolete staff fields.
DECLARE @sql NVARCHAR(MAX) = N'';
SELECT @sql = @sql + N'ALTER TABLE staff_profiles DROP CONSTRAINT ' + QUOTENAME(dc.name) + N';'
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE dc.parent_object_id = OBJECT_ID('staff_profiles')
  AND c.name IN ('staff_code', 'legacy_staff_code', 'salary');
EXEC sp_executesql @sql;

SET @sql = N'';
SELECT @sql = @sql + N'ALTER TABLE staff_profiles DROP CONSTRAINT ' + QUOTENAME(kc.name) + N';'
FROM sys.key_constraints kc
WHERE kc.parent_object_id = OBJECT_ID('staff_profiles') AND kc.type = 'UQ'
  AND EXISTS (
    SELECT 1 FROM sys.index_columns ic
    JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
    WHERE ic.object_id = kc.parent_object_id AND ic.index_id = kc.unique_index_id
      AND c.name IN ('staff_code', 'legacy_staff_code', 'salary')
  );
EXEC sp_executesql @sql;

ALTER TABLE staff_profiles DROP COLUMN staff_code, legacy_staff_code, salary;
DROP SEQUENCE IF EXISTS staff_code_sequence;
