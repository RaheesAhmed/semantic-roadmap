CREATE PROCEDURE [spa].[SetEvent]
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
		
        -- dbml
        -- SELECT * FROM dbo.mEvent;

        DECLARE @sThisTableName VARCHAR(50) = 'mEvent' ,-- For RowID
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
        
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
        
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetEventDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID BIGINT ,
            wName NVARCHAR(100),
            wCode NVARCHAR(30),
            wStartDate DATE,
            wEndDate DATE,
            wType VARCHAR(10),
            wColorRGB VARCHAR(7),
            wStatus VARCHAR(10),
            wBookingStartDate DATE,
            wBookingEndDate DATE,
            wSunCRMStartDate DATE,
            wSunCRMEndDate DATE,
            wCrtDt DATETIME2(7),
            wCrtBy  BIGINT ,
            wUpdDt DATETIME2(7),
            wUpdBy BIGINT
        );

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            DECLARE @sErrorMsg NVARCHAR(MAX);
        
            IF NULLIF(@sErrorMsg, '') IS NULL AND ISNULL(@pActionType, '') NOT IN ('I', 'U', 'D')
                SET @sErrorMsg = N'非法操作！';

            IF NULLIF(@sErrorMsg, '') IS NULL AND @pActionType IN ( 'I', 'U' )
            BEGIN
                SELECT @sErrorMsg = CASE WHEN NULLIF(wName, '') IS NULL THEN N'事件名稱不能為空。'
                                         WHEN NULLIF(wCode, '') IS NULL THEN N'事件編號不能為空。'
                                         WHEN wStartDate IS NULL THEN N'開始日期不能為空。'
                                         WHEN wEndDate IS NULL THEN N'結束日期不能為空。'
                                         WHEN wStartDate > wEndDate THEN N'開始日期不能大於結束日期。'
                                         WHEN wBookingStartDate IS NOT NULL AND wBookingEndDate IS NOT NULL AND wBookingStartDate > wBookingEndDate THEN N'預訂開始日期不能大於截止日期。'
                                         WHEN wSunCRMStartDate IS NOT NULL AND wSunCRMEndDate IS NOT NULL AND wSunCRMStartDate > wSunCRMEndDate THEN N'SunCRM開始日期不能大於結束日期。'
                                    END
                FROM    #sDataSet_SetEventDetails;
            END;

            IF NULLIF(@sErrorMsg, '') IS NOT NULL
                THROW 50001, @sErrorMsg, 1;	

            IF @pActionType = 'I'
            BEGIN
                IF EXISTS ( SELECT 1
                            FROM dbo.mEvent AS me
                            INNER JOIN #sDataSet_SetEventDetails te ON te.wName = me.wName )
                    THROW 50001, N'事件名稱已存在。', 1;

                IF EXISTS ( SELECT 1
                            FROM dbo.mEvent AS me
                            INNER JOIN #sDataSet_SetEventDetails te ON te.wCode = me.wCode )
                    THROW 50001, N'事件編碼已存在。', 1;

                IF EXISTS ( SELECT  1
                            FROM dbo.mEvent AS me
                            INNER JOIN #sDataSet_SetEventDetails te ON te.wColorRGB = me.wColorRGB )
                    THROW 50001, N'事件代表顏色已存在。', 1;

                -- Set RowID by Sequence
                SELECT  @sRecCount = COUNT(1) FROM #sDataSet_SetEventDetails;

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                    UPDATE  #sDataSet_SetEventDetails
                    SET     RowID = @sRowID
                    WHERE   wRowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;    		        
								
                INSERT  INTO dbo.[mEvent]
                ( 
                    RowID ,
                    wName ,
                    wCode,
                    wStartDate ,
                    wEndDate ,
                    wType,
                    wColorRGB,
                    wStatus ,
                    wBookingStartDate,
                    wBookingEndDate,
                    wSunCRMStartDate,
                    wSunCRMEndDate,
                    wCrtDt ,
                    wCrtBy ,
                    wUpdDt ,
                    wUpdBy
                )
                SELECT
                    te.RowID ,
                    te.wName ,
                    te.wCode,
                    te.wStartDate ,
                    te.wEndDate ,
                    te.wType,
                    te.wColorRGB,
                    te.wStatus ,
                    te.wBookingStartDate,
                    te.wBookingEndDate,
                    te.wSunCRMStartDate,
                    te.wSunCRMEndDate,
                    @sNow ,
                    te.wCrtBy ,
                    @sNow ,
                    te.wUpdBy
                FROM #sDataSet_SetEventDetails te;
            END;
            ELSE IF @pActionType = 'U'
            BEGIN
                IF EXISTS ( SELECT 1
                            FROM dbo.mEvent AS me
                            INNER JOIN #sDataSet_SetEventDetails te ON te.wName = me.wName AND te.RowID <> me.RowID )
                    THROW 50001, N'事件名稱已存在。', 1;

                IF EXISTS ( SELECT 1
                            FROM dbo.mEvent AS me
                            INNER JOIN #sDataSet_SetEventDetails te ON te.wCode = me.wCode AND te.RowID <> me.RowID )
                    THROW 50001, N'事件編碼已存在。', 1;

                IF EXISTS ( SELECT  1
                            FROM dbo.mEvent AS me
                            INNER JOIN #sDataSet_SetEventDetails te ON te.wColorRGB = me.wColorRGB AND te.RowID <> me.RowID )
                    THROW 50001, N'事件代表顏色已存在。', 1;

                UPDATE me
                SET     
                    me.wName = te.wName ,
                    me.wCode = te.wCode ,
                    me.wStartDate = te.wStartDate ,
                    me.wEndDate = te.wEndDate ,
                    me.wType = te.wType ,
                    me.wColorRGB = te.wColorRGB ,
                    me.wStatus = te.wStatus ,
                    me.wBookingStartDate = te.wBookingStartDate,
                    me.wBookingEndDate = te.wBookingEndDate,
                    me.wSunCRMStartDate = te.wSunCRMStartDate,
                    me.wSunCRMEndDate = te.wSunCRMEndDate,
                    me.wUpdDt = @sNow ,
                    me.wUpdBy = te.wUpdBy
                FROM dbo.mEvent AS me
                INNER JOIN #sDataSet_SetEventDetails te ON te.RowID = me.RowID
            END;
            ELSE IF @pActionType = 'D'
            BEGIN
                UPDATE  me
                SET
                    me.wStatus = 'T' ,
                    me.wUpdDt = dbo.fnUTC8Now(),
                    me.wUpdBy = ISNULL(te.wUpdBy, me.wUpdBy)
                FROM dbo.mEvent AS me
                INNER JOIN #sDataSet_SetEventDetails te ON te.RowID = me.RowID
            END;

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

		-- Return RowID affected
            IF @pReturnResultSet = 'Y'
                SELECT RowID FROM #sDataSet_SetEventDetails;
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

        IF OBJECT_ID('tempdb..#sDataSet_SetEventDetails') IS NOT NULL
            DROP TABLE #sDataSet_SetEventDetails;
    END;