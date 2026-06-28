CREATE PROCEDURE [spa].[SetDeptReqRoomLog]
    @pXML               XML ,
    @pActionType        CHAR(1) , -- I/U/D
    @pMainCompNo        INT ,
    @pReturnResult      CHAR(1) = 'N',
    @pTestMode          INT = 0,
    @pErrCode           INT = 0 OUTPUT ,
    @pErrMsg            NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        -------------------------------------------------
         --SELECT RowID FROM dbo.eDeptReqRoomLog;
        -------------------------------------------------

        DECLARE @sThisTableName     VARCHAR(50) = 'eDeptReqRoomLog' ,
                @sBeginTranCount	INT = 0 ,
                @sDocHandle			INT,
                @sRecCount			INT = 0,
                @sRuningIndex		INT = 1,
                @sRowID				BIGINT = 0,
                @sNow				DATETIME2 = dbo.fnUTC8Now(),
                @sErrMsg            NVARCHAR(200);
        
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
                *
        INTO    #sDataSet_SetDeptReqRoomLog
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
		WITH (  RowID BIGINT,
                wAgentCodeIn VARCHAR(14),
                wRemark NVARCHAR(4000),
                wRemarkDt DATETIME2(7),
                wStatus CHAR(1),
                wCrtBy BIGINT,
                wCrtDt DATETIME2(7),
                wUpdBy BIGINT,
                wUpdDt DATETIME2(7)
        );

        EXEC sp_xml_removedocument @sDocHandle;

        SET @pErrCode = 0 ;
        SET @pErrMsg = '';
        SET @sBeginTranCount = @@TRANCOUNT;

        BEGIN TRY	                
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            ---------------------------------------------------------------Checking-----------------------------------------------------------
            SET @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetDeptReqRoomLog);
            IF NULLIF(@sErrMsg, '') IS NULL AND @sRecCount = 0
                SET @sErrMsg = N'沒有數據需要保存';

            IF NULLIF(@sErrMsg, '') IS NULL AND @sRecCount > 1
                SET @sErrMsg = N'不支持同時保存多條數據';

            IF NULLIF(@sErrMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
                SET @sErrMsg = N'非法操作';

            IF NULLIF(@sErrMsg, '') IS NOT NULL
                THROW 50001, @sErrMsg, 1;
            -------------------------------------------------------------End Checking-----------------------------------------------------------
        		
            IF @pActionType = 'I'
            BEGIN
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetDeptReqRoomLog);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT
                    
                    UPDATE #sDataSet_SetDeptReqRoomLog
                    SET RowID = @sRowID 
                    WHERE wRowNum = @sRuningIndex

                    SET @sRuningIndex = @sRuningIndex + 1;
                END	

                INSERT INTO [dbo].[eDeptReqRoomLog] (
                    RowID,
                    wAgentCodeIn,
                    wRemark,
                    wRemarkDt,
                    wStatus,
                    wCrtBy,
                    wCrtDt,
                    wUpdBy,
                    wUpdDt   
                )
                SELECT RowID,
                       wAgentCodeIn,
                       wRemark,
                       wRemarkDt,
                       wStatus, 
                       wUpdBy, 
                       @sNow, 
                       wUpdBy, 
                       @sNow
                FROM #sDataSet_SetDeptReqRoomLog;
            END
            
            IF @pActionType = 'U'
            BEGIN
                UPDATE dlog
                SET --wAgentCodeIn = tmp.wAgentCodeIn,
                    wRemark     = tmp.wRemark,
                    wRemarkDt   = tmp.wRemarkDt,
                    wStatus     = tmp.wStatus,
                    wUpdBy      = tmp.wUpdBy,
                    wUpdDt      = @sNow
                FROM [dbo].[eDeptReqRoomLog] dlog 
                INNER JOIN #sDataSet_SetDeptReqRoomLog tmp ON tmp.RowID = dlog.RowID
            END
            
            IF @pActionType = 'D'
            BEGIN
                UPDATE  dlog
                SET wStatus = 'T' ,
                    wUpdBy = tmp.wUpdBy,
                    wUpdDt = @sNow
                FROM [dbo].[eDeptReqRoomLog] dlog 
                INNER JOIN #sDataSet_SetDeptReqRoomLog tmp ON tmp.RowID = dlog.RowID
            END;

            ----------------------------------------------------------------------------------
            IF @sBeginTranCount = 0 AND @@TRANCOUNT > 0
            BEGIN
                IF @pTestMode = 1
                    ROLLBACK TRAN
                ELSE
                    COMMIT TRAN;
            END

            -- return result
            ----------------------------------------------------------------------------------
            IF @pReturnResult = 'Y'
			    SELECT RowID FROM #sDataSet_SetDeptReqRoomLog;
            ----------------------------------------------------------------------------------
        END TRY
        BEGIN CATCH
            DECLARE @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sCatchErrorCode INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
	        
            SET @xstate             = XACT_STATE();
            SET @sProcedureName     = OBJECT_NAME(@@PROCID);
            SET @sCatchErrorCode    = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            
            SET @pErrCode = IIF(ISNULL(@pErrCode, 0) = 0, @sCatchErrorCode, @pErrCode);
            SET @pErrMsg = CONCAT(IIF(ISNULL(@pErrMsg, '') = '', '', @pErrMsg + CHAR(10)), '(', @sCatchErrorCode, ') ', @sCatchErrorMessage);
			
            IF @sBeginTranCount = 0 AND ( @xstate = 1 OR @xstate = -1 )
            BEGIN
                ROLLBACK TRAN;
            END
            ELSE
                THROW;
	        
            EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;        
        END CATCH;

        IF OBJECT_ID('tempdb..#sDataSet_SetDeptReqRoomLog') IS NOT NULL
            DROP TABLE #sDataSet_SetDeptReqRoomLog;
    END;