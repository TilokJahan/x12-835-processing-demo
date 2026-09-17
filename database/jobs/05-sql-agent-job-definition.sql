/*
    Version 1 SQL Agent orchestration reference.

    This script is optional for the first local test. It demonstrates how the
    multi-step SQL Agent workflow can be represented without depending on an
    actual cloud retrieval provider.

    Run in msdb only if you want to inspect/create the disabled demo job.
*/

USE msdb;
GO

IF EXISTS
(
    SELECT 1
    FROM dbo.sysjobs
    WHERE name = N'X12-835-Demo-Processing'
)
    EXEC dbo.sp_delete_job
        @job_name = N'X12-835-Demo-Processing';
GO

EXEC dbo.sp_add_job
    @job_name = N'X12-835-Demo-Processing',
    @enabled = 0,
    @description = N'Portfolio demonstration of a multi-step X12 835 workflow.';
GO

EXEC dbo.sp_add_jobstep
    @job_name = N'X12-835-Demo-Processing',
    @step_name = N'1 - Register inbound file',
    @subsystem = N'TSQL',
    @database_name = N'X12835Demo',
    @command = N'PRINT ''External/cloud retrieval is simulated in Version 1.'';';
GO

EXEC dbo.sp_add_jobstep
    @job_name = N'X12-835-Demo-Processing',
    @step_name = N'2 - Parse 835',
    @subsystem = N'TSQL',
    @database_name = N'X12835Demo',
    @command = N'PRINT ''Invoke dbo.Parse835Batch for the registered batch.'';';
GO

EXEC dbo.sp_add_jobstep
    @job_name = N'X12-835-Demo-Processing',
    @step_name = N'3 - Post ledger',
    @subsystem = N'TSQL',
    @database_name = N'X12835Demo',
    @command = N'PRINT ''Invoke dbo.Post835Ledger for the parsed batch.'';';
GO

EXEC dbo.sp_add_jobstep
    @job_name = N'X12-835-Demo-Processing',
    @step_name = N'4 - Reconcile batch',
    @subsystem = N'TSQL',
    @database_name = N'X12835Demo',
    @command = N'PRINT ''Invoke dbo.Reconcile835Batch after posting.'';';
GO

EXEC dbo.sp_update_job
    @job_name = N'X12-835-Demo-Processing',
    @enabled = 0;
GO

PRINT 'SQL Agent job definition created in disabled state.';
GO
