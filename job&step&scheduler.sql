USE msdb;
GO

EXEC sp_add_job
    @job_name = N'Hospital_Weekly_Snapshot',
    @enabled = 1,
    @description = N'Weekly snapshot of hospital transactional tables (Visits, Admissions, Bills, etc.)';
GO

EXEC sp_add_jobstep
    @job_name = N'Hospital_Weekly_Snapshot',
    @step_name = N'Run dbo.RunWeeklySnapshot',
    @subsystem = N'TSQL',
    @database_name = N'Hospital_Salam',
    @command = N'EXEC dbo.RunWeeklySnapshot;',
    @on_success_action = 1,   -- Quit with success
    @on_fail_action    = 2;   -- Quit with failure
GO
EXEC sp_add_schedule
    @schedule_name = N'Weekly_Monday_1AM',
    @freq_type = 8,           -- Weekly
    @freq_interval = 2,       -- Monday (1=Sunday, 2=Monday, 4=Tuesday, ... bitmask)
    @freq_recurrence_factor = 1, 
    @active_start_time = 010000;  -- 01:00 AM
GO


EXEC sp_attach_schedule
    @job_name = N'Hospital_Weekly_Snapshot',
    @schedule_name = N'Weekly_Monday_1AM';
GO

EXEC sp_add_jobserver
    @job_name = N'Hospital_Weekly_Snapshot',
    @server_name = N'(local)';
GO
