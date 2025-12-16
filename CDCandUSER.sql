-- 1) CDC
USE master;
GO
ALTER DATABASE Hospital_Salam
SET ALLOW_SNAPSHOT_ISOLATION ON;
GO

USE Hospital_Salam;
GO
EXEC sys.sp_cdc_enable_db;
GO


EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'Visits',
    @role_name     = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'VisitStatusHistory',
    @role_name     = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'Admissions',
    @role_name     = NULL,
    @supports_net_changes = 0;
GO

EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo',
    @source_name   = 'Bills',
    @role_name     = NULL,
    @supports_net_changes = 0;
GO



--create user
USE master;
GO

CREATE LOGIN debezium_user3
WITH PASSWORD = 'StrongPass!123';
GO

USE Hospital_Salam;
GO

CREATE USER debezium_user3
FOR LOGIN debezium_user3;
GO


ALTER ROLE db_owner
ADD MEMBER debezium_user3;
GO

USE master;
GO
GRANT VIEW SERVER STATE TO debezium_user3;
GO

