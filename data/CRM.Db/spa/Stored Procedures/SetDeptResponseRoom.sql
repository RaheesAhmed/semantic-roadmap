
CREATE PROCEDURE [spa].[SetDeptResponseRoom]
    @pXML           XML ,
    @pActionType    CHAR(1) , -- I/U/D
    @pMainCompNo    INT ,
    @pReturnResult  CHAR(1) = 'N',
    @pTestMode      INT = 0,
    @pErrCode       INT = 0 OUTPUT ,
    @pErrMsg        NVARCHAR(200) = '' OUTPUT 
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        -------------------------------------------------
        -- SELECT * FROM dbo.eDeptRespRoom
        -------------------------------------------------

        DECLARE @sThisTableName     VARCHAR(50) = 'eDeptRespRoom' ,-- For RowID
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sDocHandle         INT,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now(),
                @sErrCode           INT,
                @sErrMsg            NVARCHAR(200);
          
        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetDeptRespRoomDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (  RowID BIGINT,
                wDeptReqRoomRid BIGINT,
                wHotelRid BIGINT,
                wRoomRid BIGINT,
                wBigBedQty INT,
                wTwinBedQty INT,
                wSuiteRoom1Qty INT,
                wSuiteRoom2Qty INT,
                wSuiteRoom3Qty INT,
                wDayOfStay INT,
                wStartDate DATE ,
                wEndDate DATE,
                wStatus VARCHAR(20),
                wRepStatus VARCHAR(20),
                wOldRepStatus VARCHAR(20),
                wRemark NVARCHAR(4000),
                wCrtDt DATETIME2(7),
                wCrtBy BIGINT,
                wUpdDt DATETIME2(7),
                wUpdBy BIGINT,
                wIsApproved CHAR(1),
                wTotalAmount NUMERIC(18, 4),
                wDeptStatus VARCHAR(20),
                wOldDeptStatus VARCHAR(20),
                wBookingRid BIGINT,
                wCancelReason NVARCHAR(500),
                wGUID UNIQUEIDENTIFIER,
                wIsExtRoom CHAR(1)
        );

        EXEC sp_xml_removedocument @sDocHandle;

        SET @pErrCode = 0;
        SET @pErrMsg = '';
        SET @sBeginTranCount = @@trancount;

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            ---------------------------------------------------------------Checking-----------------------------------------------------------
            IF NULLIF(@sErrMsg, '') IS NULL AND @pActionType NOT IN ('I', 'U', 'D')
                SET @sErrMsg = N'非法操作！';	

            IF NULLIF(@sErrMsg, '') IS NULL AND @pActionType IN ( 'I', 'U' )
            BEGIN
                IF EXISTS (SELECT 1 FROM #sDataSet_SetDeptRespRoomDetails WHERE NULLIF(wRepStatus, '') IS NULL)
                    SET @sErrMsg = N'回覆狀態不能為空。';
            END;

            IF NULLIF(@sErrMsg, '') IS NULL AND @pActionType IN ( 'U', 'D' )
            BEGIN
                IF EXISTS (SELECT 1 FROM #sDataSet_SetDeptRespRoomDetails AS resp LEFT JOIN dbo.eDeptReqRoom AS req ON req.RowID = resp.wDeptReqRoomRid WHERE req.RowID IS NULL)
                    SET @sErrMsg = N'未找到相關的部門酒店訂房請求記錄。';
            END;
            
            IF NULLIF(@sErrMsg, '') IS NULL AND @pActionType IN ('U', 'D')
            BEGIN
                IF EXISTS (SELECT 1 FROM #sDataSet_SetDeptRespRoomDetails tmp WHERE tmp.wGUID IS NULL OR tmp.wGUID = '00000000-0000-0000-0000-000000000000')
                BEGIN
                    SET @sErrMsg = N'wGUID is null';
                END
                ELSE IF EXISTS (SELECT 1 FROM dbo.eDeptRespRoom dr INNER JOIN #sDataSet_SetDeptRespRoomDetails tmp ON tmp.RowID = dr.RowID WHERE dr.wGUID <> tmp.wGUID)
                BEGIN
                    SET @sErrMsg = N'需求訂單已被修改。';
                END
            END

            IF NULLIF(@sErrMsg, '') IS NOT NULL
                THROW 50001, @sErrMsg, 1;	
            -------------------------------------------------------------End Checking-----------------------------------------------------------

            IF @pActionType = 'I'
            BEGIN
                SET @sRuningIndex = 1;
                SET  @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetDeptRespRoomDetails);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;
					
                    UPDATE  #sDataSet_SetDeptRespRoomDetails
                    SET     RowID = @sRowID
                    WHERE   wRowNum = @sRuningIndex;
                    
                    SET @sRuningIndex = @sRuningIndex + 1;
                END;    		        
								
                INSERT INTO  dbo.eDeptRespRoom (
                    RowID,
                    wDeptReqRoomRid,
                    wHotelRid,
                    wRoomRid,
                    wBigBedQty,
                    wTwinBedQty,
                    wSuiteRoom1Qty,
                    wSuiteRoom2Qty,
                    wSuiteRoom3Qty,
                    wDayOfStay,
                    wStartDate ,
                    wEndDate,
                    wStatus,
                    wRepStatus,
                    wRemark,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy,
                    wIsApproved,
                    wTotalAmount,
                    wDeptStatus,
                    wBookingRid,
                    wCancelReason,
                    wGUID,
                    wIsExtRoom
                )
                SELECT  
                    RowID,
                    wDeptReqRoomRid,
                    wHotelRid,
                    wRoomRid,
                    wBigBedQty,
                    wTwinBedQty,
                    wSuiteRoom1Qty,
                    wSuiteRoom2Qty,
                    wSuiteRoom3Qty,
                    wDayOfStay,
                    wStartDate ,
                    wEndDate,
                    'A',
                    wRepStatus,
                    wRemark,
                    @sNow,
                    wCrtBy,
                    @sNow,
                    wUpdBy,
                    wIsApproved,
                    wTotalAmount,
                    wDeptStatus,
                    wBookingRid = 0,
                    wCancelReason = '',
                    NEWID(),
                    wIsExtRoom = IIF(wIsExtRoom = 'Y', 'Y', 'N')
                FROM  #sDataSet_SetDeptRespRoomDetails;
            END;
            
            IF @pActionType = 'U'
            BEGIN
                -- 先保留一份舊的部門狀態，後面SMS要用到
                UPDATE tmp
                SET wOldDeptStatus = dr.wDeptStatus,
                    wOldRepStatus = dr.wRepStatus
                FROM dbo.eDeptRespRoom dr
                INNER JOIN #sDataSet_SetDeptRespRoomDetails tmp ON tmp.RowID = dr.RowID;

                -- 需求狀態 = “完成”，更新一次房價（暫時先註釋掉，後面可能會用到）
                ----------------------------------------------------------------------------------------------------------------------
                --IF EXISTS (SELECT 1 FROM #sDataSet_SetDeptRespRoomDetails WHERE wOldRepStatus <> wRepStatus AND wRepStatus = 'C')
                --BEGIN
                --    DECLARE @pHotelRoomRid  BIGINT,
                --            @pStartDate     DATE,
                --            @pEndDate       DATE,
                --            @sPerRoomAmount  NUMERIC(18, 4);

                --    CREATE TABLE #vHotelRoomDaily(wRoomRid BIGINT, wDate DATE, wRoomPrice NUMERIC(18, 4), wBreakfastPrice NUMERIC(18, 4), wRoomCost NUMERIC(18, 4), wCurrCode VARCHAR(6))

                --    SET @sRuningIndex = 1;
                --    SET @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetDeptRespRoomDetails);

                --    WHILE @sRuningIndex <= @sRecCount
                --    BEGIN
                --        IF EXISTS (SELECT 1 FROM #sDataSet_SetDeptRespRoomDetails WHERE wRowNum = @sRuningIndex AND wOldRepStatus <> wRepStatus AND wRepStatus = 'C')
                --        BEGIN
                --            SELECT @pHotelRoomRid = wRoomRid,
                --                   @pStartDate = wStartDate,
                --                   @pEndDate = wEndDate
                --            FROM #sDataSet_SetDeptRespRoomDetails
                --            WHERE wRowNum = @sRuningIndex;

                --            INSERT INTO #vHotelRoomDaily EXEC spq.GetDeptReqRoomHotelDailyLst @pHotelRoomRid, @pStartDate, @pEndDate;

                --            SET @sPerRoomAmount = (SELECT SUM(wRoomPrice + wBreakfastPrice) FROM #vHotelRoomDaily);

                --            UPDATE #sDataSet_SetDeptRespRoomDetails SET wTotalAmount = ISNULL(@sPerRoomAmount, 0) * (wBigBedQty + wTwinBedQty +  wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty) WHERE wRowNum = @sRuningIndex;

                --            DELETE FROM #vHotelRoomDaily;
                --        END
                    
                --        SET @sRuningIndex = @sRuningIndex + 1;
                --    END
                --END
                ----------------------------------------------------------------------------------------------------------------------

                UPDATE  dr
                SET wHotelRid       = tmp.wHotelRid,
                    wRoomRid        = tmp.wRoomRid,
                    wBigBedQty      = tmp.wBigBedQty,	
                    wTwinBedQty     = tmp.wTwinBedQty,  
                    wSuiteRoom1Qty  = tmp.wSuiteRoom1Qty,	
                    wSuiteRoom2Qty  = tmp.wSuiteRoom2Qty,
                    wSuiteRoom3Qty  = tmp.wSuiteRoom3Qty,
                    wDayOfStay      = tmp.wDayOfStay,
                    wStartDate      = tmp.wStartDate,
                    wEndDate        = tmp.wEndDate,
                    wStatus         = tmp.wStatus,
                    wRepStatus      = tmp.wRepStatus,
                    wRemark         = tmp.wRemark,
                    wUpdDt          = @sNow,
                    wUpdBy          = tmp.wUpdBy,
                    wIsApproved     = tmp.wIsApproved,
                    wTotalAmount    = tmp.wTotalAmount,
                    wDeptStatus     = tmp.wDeptStatus,
                    dr.wBookingRid  = IIF(dr.wBookingRid <= 0, ISNULL(tmp.wBookingRid, 0), dr.wBookingRid), -- 如果已經關聯了酒店訂單，不能重新關聯到另外一張單
                    wCancelReason   = ISNULL(tmp.wCancelReason, dr.wCancelReason),
                    wGUID           = NEWID(),
                    wIsExtRoom      = IIF(tmp.wIsExtRoom = 'Y', 'Y', 'N')
                FROM dbo.eDeptRespRoom dr
                INNER JOIN #sDataSet_SetDeptRespRoomDetails tmp ON tmp.RowID = dr.RowID;

                -- 2019-04-29：Check以下這部代碼看起來沒什麽用，需求狀態沒有這個Code，永遠都執行不到裡面的SQL
                -- 例如市場部起了一條record，要求星際酒店1間雙床房，save 了以後，系統自動生成服務部可提供數量記錄，要求數量這時要拿服務部的數據，所以是計算星際酒店
                -- 之後服務部如果只能提供mgm酒店，職員就要在可提供房數記錄內更改酒店為mgm，這時mgm的要求數量會變為1，而星際酒店則減1，等服務部完成記錄後，mgm完成數量會為1
                --IF (SELECT COUNT(1) FROM dbo.eDeptRespRoom dr
                --    INNER JOIN #sDataSet_SetDeptRespRoomDetails tmp ON tmp.RowID = dr.RowID
                --    WHERE dr.RowID = tmp.RowID AND dr.wRepStatus = 'COMPLETED' )	> 0
                --BEGIN
                --    DECLARE @sHotelRid BIGINT,
                --            @sRoomRid BIGINT,
                --            @sRequestNo VARCHAR(30);

                --    SELECT TOP(1) @sHotelRid  = dr.wHotelRid,
                --                  @sRoomRid   = dr.wRoomRid,
                --                  @sRequestNo = dr.wRequestNo
                --    FROM dbo.eDeptRespRoom dr
                --    INNER JOIN #sDataSet_SetDeptRespRoomDetails tmp ON tmp.RowID = dr.RowID
                --    WHERE dr.RowID = tmp.RowID AND dr.wRepStatus = 'COMPLETED';

                --    IF EXISTS(SELECT 1 FROM dbo.eDeptReqRoom WHERE wRequestNo = @sRequestNo) AND NOT EXISTS(SELECT 1 FROM dbo.eDeptReqRoom WHERE wRequestNo = @sRequestNo AND wHotelRid = @sHotelRid AND wRoomRid = @sRoomRid)
                --    BEGIN
                --        UPDATE dbo.eDeptReqRoom SET wRespFlag = 'N' WHERE wRequestNo = @sRequestNo
                --    END
                --    ELSE IF EXISTS(SELECT 1 FROM dbo.eDeptReqRoom WHERE wRequestNo = @sRequestNo AND wHotelRid = @sHotelRid AND wRoomRid = @sRoomRid)
                --    BEGIN
                --        UPDATE dbo.eDeptReqRoom SET wRespFlag = 'Y' WHERE wRequestNo = @sRequestNo
                --    END
                --END
            END;
            
            IF @pActionType = 'D'
            BEGIN
                UPDATE dr
                SET wStatus = 'T' ,
                    wUpdBy = tmp.wUpdBy,
                    wUpdDt = @sNow
                FROM dbo.eDeptRespRoom dr
                INNER JOIN #sDataSet_SetDeptRespRoomDetails tmp ON tmp.RowID = dr.RowID;
            END;

            -- 訂房做過任何回覆，自動把記錄標識為“已處理”: eDeptReqRoom.wIsNewReqRoom = 'N'
            -------------------------------------------------------------------------------------------------------
            -- Update dbo.eDeptReqRoom.wReqStatus
            SET @pXML = (SELECT wDeptReqRoomRid, wUpdBy FROM #sDataSet_SetDeptRespRoomDetails FOR XML RAW('Record'), ROOT('DataSet'));
            -- 沒有RowID時，不需要Update dbo.eDeptReqRoom.wReqStatus
            IF @pXML IS NOT NULL
            BEGIN
            EXEC util.RecalDeptRoomStatus @pXML = @pXML;
            END
            
            UPDATE req
            SET wIsNewReqRoom = 'N'
            FROM dbo.eDeptReqRoom req
            INNER JOIN #sDataSet_SetDeptRespRoomDetails tmp ON tmp.wDeptReqRoomRid = req.RowID
            WHERE req.wIsNewReqRoom = 'Y'
                AND req.wReqStatus IN ('CL', 'RJ');

            -- 同步狀態到訂務需求eReqBooking.wReqStatus
            IF @pActionType IN ('U', 'D') AND @pXML IS NOT NULL
                EXEC util.RecalReqBookingHotelStatus @pXML = @pXML, @pMainCompNo = @pMainCompNo, @pErrCode = @sErrCode OUTPUT, @pErrMsg = @sErrMsg OUTPUT;

            -------------------------------------------------------------------------------------------------------

            -- 2019-05-16：OP#28681，如果部門狀態由 CB -> RA，wApplyDepartment --> MD、VIP、SC_ROOM， 由 RA --> CB，wApplyDepartment --> SC_ROOM
            -------------------------------------------------------------------------------------------------------
            IF NULLIF(@sErrMsg, '') IS NULL AND EXISTS (SELECT 1 FROM #sDataSet_SetDeptRespRoomDetails WHERE (wOldDeptStatus = 'CB' AND wDeptStatus = 'RA') OR (wOldDeptStatus = 'RA' AND wDeptStatus = 'CB'))
            BEGIN
                DECLARE @vApplyUser TABLE (wDeptReqRoomRid BIGINT, wDept VARCHAR(30));
                INSERT INTO @vApplyUser(wDeptReqRoomRid, wDept)
                SELECT DISTINCT 
                       tmp.wDeptReqRoomRid, 
                       wDept = CASE tmp.wDeptStatus WHEN 'RA' THEN IIF(mu.wDept = 'ROOM', 'SC_ROOM', mu.wDept) -- 場館服務部
                                                    WHEN 'CB' THEN IIF(req.wRequestDepartment = 'ROOM', 'CS_ROOM', req.wRequestDepartment) -- 中央訂房部
                                                    ELSE 'DEVELOP' END
                FROM dbo.eDeptReqRoom req WITH(NOLOCK)
                INNER JOIN #sDataSet_SetDeptRespRoomDetails tmp ON tmp.wDeptReqRoomRid = req.RowID
                INNER JOIN RollsMary.dbo.mUsr mu WITH(NOLOCK) ON mu.RowID = req.wApplyStaffRid
                WHERE (tmp.wOldDeptStatus = 'CB' AND tmp.wDeptStatus = 'RA') 
                    OR (tmp.wOldDeptStatus = 'RA' AND tmp.wDeptStatus = 'CB');

                UPDATE dr
                SET wApplyDepartment = au.wDept
                FROM dbo.eDeptReqRoom dr
                INNER JOIN @vApplyUser au ON au.wDeptReqRoomRid = dr.RowID;
            END
            -------------------------------------------------------------------------------------------------------

            -- 2019-04-28改：
            -- Old：
            -- Send SMS 
            -- 客人取消（3）--> 通知MD、VIP部門訂單跟進人 --> SetDeptResponseRoom
            -- 客人取消（2）--> RollsMary界面 --> SetSMSDeptResponseRoom、SunPeople --> SUNCRM_SetDeptRoomResponse
            -- 訂單完成 --> ActionBookingHotel --> SetSMSDeptResponseRoom
            -- New: 
            -- 客人取消（3）、客人取消（2）、訂單完成 --> SetDeptResponseRoom
            -------------------------------------------------------------------------------------------------------
            IF NULLIF(@sErrMsg, '') IS NULL AND @pActionType = 'U'
            BEGIN
                    DECLARE @sDeptRespRoomRid BIGINT;
                    DECLARE curDeptRespRoom CURSOR 
                    FOR 
                        SELECT RowID 
                        FROM #sDataSet_SetDeptRespRoomDetails tmp
                        WHERE wOldDeptStatus <> wDeptStatus AND wDeptStatus IN ('C', 'CL2', 'CL3');

                    OPEN curDeptRespRoom;
                    FETCH NEXT FROM curDeptRespRoom INTO @sDeptRespRoomRid;

                    WHILE @@fetch_status = 0
                    BEGIN
                        EXEC [CRM].[spa].[SetSMSDeptResponseRoom] @pDeptRespRoomRid = @sDeptRespRoomRid, @pMainCompNo = @pMainCompNo, @pErrCode = @sErrCode OUTPUT, @pErrMsg = @sErrMsg OUTPUT;

                        FETCH NEXT FROM curDeptRespRoom INTO @sDeptRespRoomRid;
                    END;

                    CLOSE curDeptRespRoom;  
                    DEALLOCATE curDeptRespRoom;
            END;
            -------------------------------------------------------------------------------------------------------

            -- 2019-04-12：OP#25956, Write Action Log
            -------------------------------------------------------------------------------------------------------
            IF NULLIF(@sErrMsg, '') IS NULL
            BEGIN
                DECLARE @vDeptRespRoomXML XML;
                SET @vDeptRespRoomXML = (SELECT RowID FROM #sDataSet_SetDeptRespRoomDetails FOR XML RAW('Record'), ROOT('DataSet'));
            
                EXEC spa.SetDeptRespRoomChange  @pDeptRespRoomXML = @vDeptRespRoomXML,
                                                @pMainCompNo      = @pMainCompNo,
                                                @pReturnResult    = 'N',
                                                @pErrCode         = @sErrCode OUTPUT,
                                                @pErrMsg          = @sErrMsg OUTPUT;
            END
            -------------------------------------------------------------------------------------------------------

            IF NULLIF(@sErrMsg, '') IS NOT NULL
                THROW 50001, @sErrMsg, 1;

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
                SELECT RowID FROM #sDataSet_SetDeptRespRoomDetails;
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

        IF OBJECT_ID('tempdb..#sDataSet_SetDeptRespRoomDetails') IS NOT NULL
            DROP TABLE #sDataSet_SetDeptRespRoomDetails;
    END;