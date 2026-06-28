

CREATE TRIGGER [CaptureCodeChanges] ON DATABASE
WITH EXECUTE AS CALLER
FOR
  DDL_FUNCTION_EVENTS,
  DDL_PROCEDURE_EVENTS,
  DDL_INDEX_EVENTS,
  DDL_TABLE_EVENTS,
  DDL_VIEW_EVENTS,
  DDL_TRIGGER_EVENTS
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @EventData XML = EVENTDATA(), @ip VARCHAR(32);

        SELECT @ip = client_net_address
            FROM sys.dm_exec_connections
            WHERE session_id = @@SPID;

        INSERT UT.dbo.CodeChanges
        (
            EventType,
            EventDDL,
            SchemaName,
            ObjectName,
            DatabaseName,
            HostName,
            IPAddress,
            ProgramName,
            LoginName
        )
        SELECT
            @EventData.value('(/EVENT_INSTANCE/EventType)[1]',   'NVARCHAR(100)'),
            @EventData.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'NVARCHAR(MAX)'),
            @EventData.value('(/EVENT_INSTANCE/SchemaName)[1]',  'NVARCHAR(255)'),
            @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]',  'NVARCHAR(255)'),
            DB_NAME(), HOST_NAME(), @ip, PROGRAM_NAME(), SUSER_SNAME();
    END TRY
    BEGIN CATCH
        -- UT.dbo.CodeChanges 在此环境不存在时静默跳过，不阻断 DDL
    END CATCH
END