-- Keep the old manually assigned code for historical reference.
ALTER TABLE staff_profiles ADD legacy_staff_code VARCHAR(20) NULL;
EXEC(N'UPDATE staff_profiles SET legacy_staff_code=staff_code');
DECLARE @uniqueName SYSNAME;
SELECT @uniqueName=kc.name FROM sys.key_constraints kc
JOIN sys.index_columns ic ON ic.object_id=kc.parent_object_id AND ic.index_id=kc.unique_index_id
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE kc.parent_object_id=OBJECT_ID('staff_profiles') AND kc.type='UQ' AND c.name='staff_code';
DECLARE @sql NVARCHAR(MAX);
IF @uniqueName IS NOT NULL
BEGIN
 SET @sql=N'ALTER TABLE staff_profiles DROP CONSTRAINT '+QUOTENAME(@uniqueName);
 EXEC(@sql);
END;
UPDATE staff_profiles SET staff_code=CONVERT(VARCHAR(20),id);
ALTER TABLE staff_profiles ALTER COLUMN staff_code BIGINT NOT NULL;
ALTER TABLE staff_profiles ADD CONSTRAINT uq_staff_numeric_code UNIQUE(staff_code);
DECLARE @next BIGINT=(SELECT COALESCE(MAX(staff_code),0)+1 FROM staff_profiles);
SET @sql=N'CREATE SEQUENCE staff_code_sequence AS BIGINT START WITH '+CONVERT(VARCHAR(20),@next)+N' INCREMENT BY 1 NO CYCLE';
EXEC(@sql);
EXEC(N'ALTER TABLE staff_profiles ADD CONSTRAINT df_staff_numeric_code DEFAULT(NEXT VALUE FOR staff_code_sequence) FOR staff_code');
