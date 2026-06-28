CREATE PROCEDURE [spa].[SetBirthday]
    @pXML XML ,
    @pActionType VARCHAR(1), -- I/U/D
    @pMainCompNo INT ,
    @pNonceToken VARCHAR(64) ,
    @pBirthdayRid BIGINT OUTPUT,
    @pErrCode INT = 0 OUTPUT ,
    @pErrMsg NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName VARCHAR(50) = 'eBirthday' ,
                @sBeginTranCount	INT = 0 ,
                @sDocHandle			INT,
                @sRecCount			INT = 0,
                @sRuningIndex		INT = 1,
                @sRowID				BIGINT = 0,
                @sNow				DATETIME2 = dbo.fnUTC8Now();
        
        SET @sBeginTranCount = @@trancount;
        SET @pErrCode = 0;
        SET @pErrMsg = '';
    
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
    
        SELECT wRowNum = ROW_NUMBER() OVER ( ORDER BY wUpdDt ) ,
               *
        INTO   #sDataSet_SetBirthday
        FROM   OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (
            RowID BIGINT,
            wVIPPersonRid BIGINT,
            wYear INT,
            wIsLeapMonth CHAR(1),
            wGiftType VARCHAR(10),
            wRegion VARCHAR(30),
            wFollowDeptRid BIGINT,
            wFollowTeamRid BIGINT,
            wFollowUsrRid BIGINT,
            wIsPushWeChat CHAR(1),
            wIsRefusedContact VARCHAR(1),
            wPresetGiftDt DATE,
            wCreditAmt NUMERIC(18,4),
            wApprovedStatus VARCHAR(5),
            wGiftStatus VARCHAR(5),
            wSMSStatus VARCHAR(5),
            wStatus CHAR(1),
            wCrtBy BIGINT,
            wCrtDt DATETIME2(7),
            wUpdBy BIGINT,
            wUpdDt DATETIME2(7)
        ); 

        EXEC sp_xml_removedocument @sDocHandle;

        BEGIN TRY	                
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            ------------------------- Checking -------------------------------
            SELECT @sRecCount = COUNT(1) FROM #sDataSet_SetBirthday;
            IF NULLIF(@pErrMsg, '') IS NULL AND @sRecCount = 0
            BEGIN
                SET @pErrMsg = N'沒有數據需要保存。';
            END;

            IF NULLIF(@pErrMsg, '') IS NULL AND @sRecCount > 1
            BEGIN
                SET @pErrMsg = N'不支持同時保存多條數據。';
            END;

            IF NULLIF(@pErrMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
            BEGIN
                SET @pErrMsg = N'非法操作';
            END;

            IF NULLIF(@pErrMsg, '') IS NULL AND @pActionType NOT IN ('U')
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM [dbo].[eBirthday] eb INNER JOIN #sDataSet_SetBirthday tmp ON tmp.RowID = eb.RowID WHERE eb.wStatus = 'A')
                    SET @pErrMsg = N'生日記錄不存在';
            END;

            IF NULLIF(@pErrMsg, '') IS NOT NULL
                THROW 50001, @pErrMsg, 1;
            ------------------------- End Checking ---------------------------
        		
            IF @pActionType = 'I'
            BEGIN
                SELECT @sRecCount = COUNT(1) FROM #sDataSet_SetBirthday

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowId @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
						
                    UPDATE #sDataSet_SetBirthday SET RowID = @sRowID WHERE wRowNum = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;
                
                INSERT INTO [dbo].[eBirthday]( 
                    RowID,
                    wVIPPersonRid,
                    wYear,
                    wIsLeapMonth,
                    wGiftType,
                    wRegion,
                    wFollowDeptRid,
                    wFollowTeamRid,
                    wFollowUsrRid,
                    wIsPushWeChat,
                    wIsRefusedContact,
                    wPresetGiftDt,
                    wCreditAmt,
                    wApprovedStatus,
                    wGiftStatus,
                    wSMSStatus,
                    wStatus,
                    wCrtBy,
                    wCrtDt,
                    wUpdBy,
                    wUpdDt
                )
                SELECT 
                    RowID,
                    wVIPPersonRid,
                    wYear,
                    wIsLeapMonth,
                    wGiftType,
                    wRegion,
                    wFollowDeptRid,
                    wFollowTeamRid,
                    wFollowUsrRid,
                    wIsPushWeChat,
                    wIsRefusedContact,
                    wPresetGiftDt,
                    wCreditAmt = 0,
                    wApprovedStatus,
                    wGiftStatus,
                    wSMSStatus,
                    wStatus,
                    wCrtBy,
                    @sNow, 
                    wUpdBy, 
                    @sNow 
                FROM #sDataSet_SetBirthday
            END;
			
            IF @pActionType = 'U'
            BEGIN
                UPDATE eb 
                SET --wVIPPersonRid = tmp.wVIPPersonRid, 
                    --wYear = tmp.wYear, 
                    --wIsLeapMonth = tmp.wIsLeapMonth, 
                    wGiftType = tmp.wGiftType, 
                    wRegion = tmp.wRegion, 
                    wFollowDeptRid = tmp.wFollowDeptRid, 
                    wFollowTeamRid = tmp.wFollowTeamRid, 
                    wFollowUsrRid = tmp.wFollowUsrRid, 
                    wIsPushWeChat = tmp.wIsPushWeChat, 
                    wIsRefusedContact = tmp.wIsRefusedContact, 
                    wPresetGiftDt = tmp.wPresetGiftDt,
                    wCreditAmt = IIF(tmp.wGiftStatus = 'Y' AND eb.wGiftStatus = 'N', tmp.wCreditAmt, 0),
                    wApprovedStatus = tmp.wApprovedStatus, 
                    wGiftStatus = tmp.wGiftStatus, 
                    wSMSStatus = tmp.wSMSStatus, 
                    wIsNew = 'N',
                    wStatus = tmp.wStatus,
                    wUpdBy = tmp.wUpdBy, 
                    wUpdDt = @sNow 
                FROM [dbo].[eBirthday] eb 
                INNER JOIN #sDataSet_SetBirthday tmp ON tmp.RowID = eb.RowID
            END;

            IF @pActionType = 'D'
            BEGIN
                UPDATE eb
                SET wStatus = 'T' ,
                    wIsNew = 'N',
                    wUpdBy = tmp.wUpdBy,
                    wUpdDt = @sNow
                FROM [dbo].[eBirthday] eb 
                INNER JOIN #sDataSet_SetBirthday tmp ON tmp.RowID = eb.RowID
            END;          

           IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

            SET @pBirthdayRid = (SELECT TOP (1) RowID FROM #sDataSet_SetBirthday);
        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
        
            SET @sErrorNum = ERROR_NUMBER();
            SET @pErrCode = ERROR_NUMBER();
            SET @sCatchErrorMessage = ERROR_MESSAGE();
            SET @xstate = XACT_STATE();
            SET @sProcedureName = OBJECT_NAME(@@PROCID);
		
            IF ISNULL(@pErrCode, 0) = 0
            BEGIN
                SET @pErrCode = 70001;
            END;

            SET @pErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);

            IF @sBeginTranCount = 0
            BEGIN
                IF @xstate != 0
                    ROLLBACK;

                -- Write Log
                EXEC spa.WriteErrorLog @pMainCompNo, @pMainCompNo, @sProcedureName, @pErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
            END;
            ELSE
                THROW;             			
                              
        END CATCH;

            IF OBJECT_ID('tempdb..#sDataSet_SetBirthday') IS NOT NULL
                DROP TABLE #sDataSet_SetBirthday;
    END;