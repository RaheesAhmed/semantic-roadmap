CREATE PROCEDURE [util].[GenerateTableBasicSP]
	@pTableName AS NVARCHAR(MAX) ,
	@pCreateGetRecord AS CHAR(1) , -- 'Y'/'N'
	@pCreateGetList AS CHAR(1) , -- 'Y'/'N'	
	@pCreateSet AS CHAR(1)  -- 'Y'/'N'
AS
	BEGIN
		SET NOCOUNT ON;
		BEGIN TRAN;

		PRINT 'Get by PK';
		EXEC util.GenerateGetRecordSP @pTableName = @pTableName, -- varchar(50)
			@pCreate = @pCreateGetRecord; -- char(1)
	
		PRINT 'Get Lst';
		EXEC util.GenerateGetListSP @pTableName = @pTableName, -- varchar(50)
			@pCreate = @pCreateGetList; -- char(1)
	
		PRINT 'Set SP';
		EXEC util.GenerateSetSP @pTableName = @pTableName, -- varchar(50)
			@pCreate = @pCreateSet; -- char(1)

		COMMIT;
	END;