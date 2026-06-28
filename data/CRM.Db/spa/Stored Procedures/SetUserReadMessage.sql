/****** Script for SelectTopNRows command from SSMS  ******/

 -- CREATE TABLE dbo.eUserReadMessage
 -- (
 --   RowID bigint primary key,
	--wUserRid bigint,
	--wRequestRid bigint,
	--wLastMessageId bigint
 -- )
 -- GO
  CREATE PROCEDURE spa.SetUserReadMessage
  (
    @pXML XML ,
    @pActionType CHAR(1) , -- I/U/D
    @pMainCompNo INT ,
    @pReturnResultSet CHAR(1) = 'N' ,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) = '' OUTPUT 
)
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eUserReadMessage' ,-- For RowID
                @sBeginTranCount INT = 0 ,
                @sRecCount INT = 0 ,
                @sRuningIndex INT = 1 ,
                @sRowID BIGINT = 0 ,
                @sDocHandle INT,
                @sNow DATETIME2(7);

        SET @sBeginTranCount = @@trancount;

        SET @pErrCode = 0;
        SET @pErrMsg = '';
        SET @sNow = dbo.fnUTC8Now();
        
        DECLARE @sReturnRowID TABLE ( RowID BIGINT );
        
		select RowID FROM @sReturnRowID

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
        
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetUserReadMessageDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
			RowID bigint,
            wUserRid bigint,
			wRequestRid bigint,
			wLastMessageId bigint
        );

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            DECLARE @sErrorMsg NVARCHAR(MAX);

            IF NULLIF(@sErrorMsg, '') IS NOT NULL
                THROW 50001, @sErrorMsg, 1;	

			IF (SELECT COUNT(*)
				FROM dbo.eUserReadMessage AS me
				INNER JOIN #sDataSet_SetUserReadMessageDetails te ON te.wUserRid = me.wUserRid AND te.wRequestRid = me.wRequestRid) > 0
				SET @pActionType = 'U'
			ELSE
				SET @pActionType = 'I'

            IF @pActionType = 'I'
            BEGIN
                -- Set RowID by Sequence
                SELECT  @sRecCount = COUNT(1) FROM #sDataSet_SetUserReadMessageDetails;

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                    UPDATE  #sDataSet_SetUserReadMessageDetails
                    SET     RowID = @sRowID
                    WHERE   wRowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;    		        
								
                INSERT  INTO dbo.[eUserReadMessage]
                ( 
                    RowID,
					wUserRid,
					wRequestRid,
					wLastMessageId
                )
                SELECT
                    RowID,
					wUserRid,
					wRequestRid,
					wLastMessageId
                FROM #sDataSet_SetUserReadMessageDetails;
            END;
            ELSE IF @pActionType = 'U'
            BEGIN

                UPDATE me
                SET     
					--me.wUserRid=wUserRid,
					--me.wRequestRid=wRequestRid,
					me.wLastMessageId = te.wLastMessageId
                FROM dbo.eUserReadMessage AS me
                INNER JOIN #sDataSet_SetUserReadMessageDetails te ON te.wUserRid = me.wUserRid AND te.wRequestRid = me.wRequestRid
            END;
            --ELSE IF @pActionType = 'D'
            --BEGIN
            --    --UPDATE  me
            --    --SET
            --    --    me.wStatus = 'T' ,
            --    --    me.wUpdDt = dbo.fnUTC8Now(),
            --    --    me.wUpdBy = ISNULL(te.wUpdBy, me.wUpdBy)
            --    --FROM dbo.mEvent AS me
            --    --INNER JOIN #sDataSet_SetUserReadMessageDetails te ON te.RowID = me.RowID
            --END;

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT RowID FROM #sDataSet_SetUserReadMessageDetails;

        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
	        
            SET @sErrorNum = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE() ;
            SET @xstate = XACT_STATE() ;
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@pErrCode, 0) = 0
                SET @pErrCode = 999;

            SET @pErrMsg = CONCAT(@pErrMsg, CHAR(10), '(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
            -- transaction created within this sp
                ROLLBACK;
            END;
	        
            -- Write Log
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
        END CATCH;
	
        EXEC sp_xml_removedocument @sDocHandle;

        IF OBJECT_ID('tempdb..#sDataSet_SetUserReadMessageDetails') IS NOT NULL
            DROP TABLE #sDataSet_SetUserReadMessageDetails;
    END;