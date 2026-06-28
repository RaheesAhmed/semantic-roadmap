CREATE PROCEDURE [spa].[SetDeptRequsetRoom]
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
        -- SELECT * FROM dbo.eDeptReqRoom
        -------------------------------------------------

        DECLARE @sThisTableName     VARCHAR(50) = 'eDeptReqRoom' ,-- For RowID
                @sRequestNo         VARCHAR(30),
                @sBeginTranCount    INT = 0 ,
                @sRecCount          INT = 0 ,
                @sRuningIndex       INT = 1 ,
                @sRowID             BIGINT = 0 ,
                @sDocHandle         INT,
                @pProcessXML        XML,
                @sNow               DATETIME2(7) = dbo.fnUTC8Now(),
                @sErrCode           INT,
                @sErrMsg            NVARCHAR(200);
		     
        DECLARE @sHotelRoomRid      BIGINT,
                @sStartDate         DATE,
                @sEndDate           DATE,
                @sTotalAmount       NUMERIC(18, 4) = 0;

        EXEC sp_xml_preparedocument @sDocHandle OUTPUT, @pXML;
	    
        SELECT  wRowNum = ROW_NUMBER() OVER ( ORDER BY RowID ) ,
                *
        INTO    #sDataSet_SetDeptReqRoomDetails
        FROM    OPENXML (@sDocHandle, 'DataSet/Record', 1)
        WITH (  RowID BIGINT ,
                wRequestNo VARCHAR(30) ,
                wRequestDepartment VARCHAR(30) , -- 需要提供房間的部門
                wAgentCodeIn VARCHAR(14) ,
                wHotelRid BIGINT ,
                wRoomRid BIGINT ,
                wBigBedQty INT ,
                wTwinBedQty INT ,
                wSuiteRoom1Qty INT ,
                wSuiteRoom2Qty INT ,
                wSuiteRoom3Qty INT ,
                wDayOfStay INT ,
                wStartDate DATE ,
                wEndDate DATE ,
                wRemark NVARCHAR(4000),
                wStaffFollowedRid BIGINT ,
                wDeptFollowedCode VARCHAR(20) , -- 2019-02-23： OP#25033， 跟進部門 = 'ROOM'
                wStatus VARCHAR(20) ,
                wRespFlag CHAR(1) ,
                wCrtDt DATETIME2(7) ,
                wCrtBy BIGINT ,
                wUpdDt DATETIME2(7) ,
                wUpdBy BIGINT ,
                wEventRid BIGINT ,
                wIsNewReqRoom CHAR(1) ,
                wIsCancel CHAR(1) ,
                wCancelDt DATETIME2(7),
                wTotalAmt NUMERIC(18, 4) ,
                wApplyStaffRid BIGINT, -- 要求同事（助理）
                wApplyDepartment VARCHAR(20), -- 要求部門（提出房間需求的部門，一般是登錄者所有的部門）
                wGUID UNIQUEIDENTIFIER,
                wIsReqBooking CHAR(1),
                wIsSunTrip CHAR(1)
        );

        EXEC sp_xml_removedocument @sDocHandle;

        SET @pErrCode = 0;
        SET @pErrMsg = '';
        SET @sBeginTranCount = @@TRANCOUNT;

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
                SELECT  @sErrMsg = CASE WHEN @pActionType = 'U' AND NULLIF(wRequestNo, '') IS NULL THEN N'需求編號不能為空。'
                                        WHEN NULLIF(wRequestDepartment, '') IS NULL THEN N'預訂部門不能為空。'
                                        WHEN NULLIF(wStartDate, '0001-01-01') IS NULL THEN N'入住日期不能為空。'
                                        WHEN NULLIF(wEndDate, '0001-01-01') IS NULL THEN N'退房日期不能為空。'
                                        WHEN wEndDate < wStartDate THEN N'入住日期不能大於退房日期。'
                                   END
                FROM #sDataSet_SetDeptReqRoomDetails;
            END;
            
            IF NULLIF(@sErrMsg, '') IS NULL AND @pActionType IN ('U', 'D')
            BEGIN
                IF EXISTS (SELECT 1 FROM #sDataSet_SetDeptReqRoomDetails tmp WHERE tmp.wGUID IS NULL OR tmp.wGUID = '00000000-0000-0000-0000-000000000000')
                BEGIN
                    SET @sErrMsg = N'wGUID is null';
                END
                ELSE IF EXISTS ( SELECT 1 FROM dbo.eDeptReqRoom dr INNER JOIN #sDataSet_SetDeptReqRoomDetails tmp ON tmp.RowID = dr.RowID WHERE dr.wGUID <> tmp.wGUID)
                BEGIN
                    SET @sErrMsg = N'需求訂單已被修改。';
                END;
            END;

            IF NULLIF(@sErrMsg, '') IS NOT NULL
                THROW 50001, @sErrMsg, 1;	
            -------------------------------------------------------------End Checking-----------------------------------------------------------

            IF @pActionType = 'I'
            BEGIN
                IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE OBJECT_ID = OBJECT_ID('seqeDeptReqRoom') AND type = 'SO')
                    CREATE SEQUENCE seqeDeptReqRoom START WITH 10000 INCREMENT BY 1 MAXVALUE 99999999999999	

                -----------------------------------------獲取RowID，需求編號-------------------------------------------
                SET @sRuningIndex = 1;
                SET  @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetDeptReqRoomDetails);

                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    -- RowID
                    EXEC spq.GetRowID @pMainCompNo, @sThisTableName, @sRowID OUTPUT;

                    -- 需求編號
                    SET @sRequestNo = FORMAT(NEXT VALUE FOR dbo.seqeDeptReqRoom, '00000000')
							
                    UPDATE  #sDataSet_SetDeptReqRoomDetails
                    SET RowID      = @sRowID, 
                        wRequestNo = CASE WHEN ISNULL(wIsReqBooking, 'N') = 'Y' THEN 'P' + @sRequestNo
                                          WHEN ISNULL(wIsSunTrip, 'N') = 'Y' THEN 'T' + @sRequestNo
                                          ELSE @sRequestNo END
                    WHERE wRowNum  = @sRuningIndex;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;
                ---------------------------------------END 獲取RowID，需求編號-----------------------------------------
                
                INSERT INTO  dbo.eDeptReqRoom(
                    RowID ,
                    wRequestNo,
                    wRequestDepartment,
                    wAgentCodeIn,
                    wHotelRid,
                    wRoomRid,
                    wBigBedQty,	
                    wTwinBedQty,  
                    wSuiteRoom1Qty,	
                    wSuiteRoom2Qty,	
                    wSuiteRoom3Qty,	
                    wDayOfStay,
                    wStartDate,
                    wEndDate,
                    wRemark,
                    wStaffFollowedRid,
                    wDeptFollowedCode,
                    wStatus,
                    wRespFlag,
                    wCrtDt,
                    wCrtBy,
                    wUpdDt,
                    wUpdBy,
                    wEventRid,
                    wIsNewReqRoom,
                    wIsCancel,
                    wCancelDt,
                    wTotalAmt,
                    wApplyStaffRid,
                    wApplyDepartment,
                    wGUID
                )
                SELECT
                    RowID ,
                    wRequestNo,
                    wRequestDepartment,
                    wAgentCodeIn,
                    wHotelRid,
                    wRoomRid,
                    wBigBedQty,	
                    wTwinBedQty,  
                    wSuiteRoom1Qty,	
                    wSuiteRoom2Qty,	
                    wSuiteRoom3Qty,	
                    wDayOfStay,
                    wStartDate,
                    wEndDate,
                    wRemark,
                    wStaffFollowedRid,
                    wDeptFollowedCode,
                    'A',
                    'Y',
                    @sNow,
                    wCrtBy,
                    @sNow,
                    wUpdBy,
                    wEventRid,
                    'Y',
                    wIsCancel,
                    wCancelDt = IIF(wIsCancel='Y', @sNow, NULL),
                    0,
                    wApplyStaffRid,
                    wApplyDepartment,
                    NEWID()
                FROM  #sDataSet_SetDeptReqRoomDetails;
                ------------------------------------------------------------------------------------------------------

                --------------------------更新預訂金額---------------------------------
                SET @sRuningIndex = 1;
                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    SELECT @sRowID        = RowID,
                           @sHotelRoomRid = IIF(wRoomRid <= 0, NULL, wRoomRid),
                           @sStartDate    = wStartDate,
                           @sEndDate      = wEndDate
                    FROM #sDataSet_SetDeptReqRoomDetails
                    WHERE wRowNum = @sRuningIndex;

                    WITH tHotelRoomDaily AS (
                        SELECT RowID = MAX(RowId)
                        FROM dbo.eAllotmentHotelDaily WITH(NOLOCK)
                        WHERE wStatus = 'A'
                            AND @sHotelRoomRid = wRoomRid
                            AND @sStartDate <= wDate AND wDate < @sEndDate
                        GROUP BY wDate, wRoomRid
                    ),
                    tResult AS (
                        SELECT ahd.wRoomRid, 
                               ahd.wDate,
                               ahd.wRoomPrice,
                               ahd.wBreakfastPrice,
                               ahd.wRoomCost,
                               ahd.wCurrCode
                        FROM tHotelRoomDaily AS hrd
                        INNER JOIN dbo.eAllotmentHotelDaily AS ahd WITH(NOLOCK) ON ahd.RowId = hrd.RowID
                    )

                   SELECT @sTotalAmount = SUM(wRoomPrice + wBreakfastPrice) FROM tResult;

                   UPDATE dr 
                   SET dr.wTotalAmt = ISNULL(@sTotalAmount, 0) * (dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
                   FROM dbo.eDeptReqRoom dr
                   WHERE dr.RowID = @sRowID;
                   ------------------------END 更新預訂金額-------------------------------

                   -- 一開始市場部新增記錄填寫要求數量，save了以後，系統要自動生成可提供數量的記錄，這條記錄內的所有資料都自動default為市場部要求記錄內的資料
                    SET @pProcessXML =  (
                        SELECT RowID           = 0 ,
                               wDeptReqRoomRid = RowID,
                               wHotelRid       = wHotelRid,
                               wRoomRid        = wRoomRid,
                               wBigBedQty      = wBigBedQty,	
                               wTwinBedQty     = wTwinBedQty,  
                               wSuiteRoom1Qty  = wSuiteRoom1Qty,
                               wSuiteRoom2Qty  = wSuiteRoom2Qty,
                               wSuiteRoom3Qty  = wSuiteRoom3Qty,
                               wDayOfStay      = wDayOfStay,
                               wStartDate      = wStartDate,
                               wEndDate        = wEndDate,
                               wStatus         = 'A',
                               wRepStatus      = IIF(ISNULL(wIsReqBooking, 'N') = 'Y', 'P', 'NEW'),
                               wDeptStatus     = IIF((wApplyDepartment = 'CS_ROOM' AND wRequestDepartment = 'ROOM') OR wRequestDepartment = wApplyDepartment, 'CB', 'RA'), -- 2018-12-06：R#54001，create record 時要求部門是同一樣的, 就跑"客人自訂"流程, 不同部門時就跑 "需求申請"流程
                               wIsApproved     = IIF((wApplyDepartment = 'CS_ROOM' AND wRequestDepartment = 'ROOM') OR wRequestDepartment = wApplyDepartment, 'Y', 'N'),   -- 2018-02-23：OP#25033： 房務部分：場館服務部（SC_ROOM），中央訂房部（CS_ROOM），當申請部門是CS_ROOM、申請部門=需求部門（包含SC_ROOM），跑"客人自訂"流程, 不同部門時就跑 "需求申請"流程
                               wTotalAmount    = ISNULL(@sTotalAmount, 0) * (wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty),
                               wBookingRid     = 0,
                               wRemark         = wRemark,
                               wCancelReason   = '',
                               wIsExtRoom      = 'N',
                               wCrtDt          = @sNow,
                               wCrtBy          = wCrtBy,
                               wUpdDt          = @sNow,
                               wUpdBy          = wUpdBy
                        FROM #sDataSet_SetDeptReqRoomDetails
                        WHERE wRowNum = @sRuningIndex
                        FOR XML RAW('Record'), ROOT('DataSet')
                    );

                    EXEC [spa].[SetDeptResponseRoom] @pProcessXML, 'I', @pMainCompNo, 'N', 0, @sErrCode OUTPUT, @sErrMsg OUTPUT;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;
            END;
            
            IF @pActionType = 'U'
            BEGIN
                UPDATE  dr
                SET wRequestNo          = tmp.wRequestNo,
                    wRequestDepartment  = tmp.wRequestDepartment,
                    wAgentCodeIn        = tmp.wAgentCodeIn,
                    wHotelRid           = tmp.wHotelRid,
                    wRoomRid            = tmp.wRoomRid,
                    wBigBedQty          = tmp.wBigBedQty,	
                    wTwinBedQty         = tmp.wTwinBedQty,  
                    wSuiteRoom1Qty      = tmp.wSuiteRoom1Qty,	
                    wSuiteRoom2Qty      = tmp.wSuiteRoom2Qty,
                    wSuiteRoom3Qty      = tmp.wSuiteRoom3Qty,
                    wDayOfStay          = tmp.wDayOfStay,
                    wStartDate          = tmp.wStartDate,
                    wEndDate            = tmp.wEndDate,
                    wRemark             = tmp.wRemark,
                    wStaffFollowedRid   = tmp.wStaffFollowedRid,
                    -- wDeptFollowedCode=tmp.wDeptFollowedCode, -- 2018-12-06： R#54001， Lock住跟進部門，所以Update時不應該更新 
                                                                -- 2019-02-23： OP#25033， 跟進部門 = 'ROOM'
                    wApplyStaffRid      = tmp.wApplyStaffRid,
                    -- wApplyDepartment    = tmp.wApplyDepartment, -- 默認不可變
                    wIsNewReqRoom       = IIF(ISNULL(tmp.wStaffFollowedRid, 0) > 0, 'N', 'Y'),
                    wStatus             = tmp.wStatus,
                    wUpdDt              = @sNow,
                    wUpdBy              = tmp.wUpdBy,
                    wIsCancel           = tmp.wIsCancel,
                    wCancelDt           = IIF(tmp.wIsCancel='Y', @sNow, NULL),
                    wGUID               = NEWID()
                FROM dbo.eDeptReqRoom dr
                INNER JOIN #sDataSet_SetDeptReqRoomDetails tmp ON tmp.RowID = dr.RowID;

                -- 2019-02-25：OP#25033，房價要在簡選時顯示最UPDATE的房價(CS確定後不可再UPDATE)
                -- 在Get的sp去dbo取，此處不用UPDATE，UPDATE也沒用，也會出現不是最UPDATE的房價
                ------------------------------------------------------------------------------
                /*
                -- 如果記錄沒有被修改過，Update sub record data
                ------------------------------------------------------------------------------
                SET @sRuningIndex = 1;
                SET @sRecCount = (SELECT COUNT(1) FROM #sDataSet_SetDeptReqRoomDetails);
                
                WHILE @sRuningIndex <= @sRecCount
                BEGIN
                    -- 記錄是否已經被修改過
                    IF EXISTS ( SELECT 1 
                                FROM #sDataSet_SetDeptReqRoomDetails tmp 
                                INNER JOIN dbo.eDeptReqRoom dr ON dr.RowID = tmp.RowID 
                                WHERE tmp.wRowNum = @sRuningIndex AND dr.wIsNewReqRoom = 'Y'
                    )
                    BEGIN
                        --------------------------更新預訂金額---------------------------------
                        SELECT @sRowID        = RowID,
                               @sHotelRoomRid = IIF(wRoomRid <= 0, NULL, wRoomRid),
                               @sStartDate    = wStartDate,
                               @sEndDate      = wEndDate
                        FROM #sDataSet_SetDeptReqRoomDetails
                        WHERE wRowNum = @sRuningIndex;

                        WITH tHotelRoomDaily AS (
                            SELECT RowID = MAX(RowId)
                            FROM dbo.eAllotmentHotelDaily
                            WHERE wStatus = 'A'
                                AND @sHotelRoomRid = wRoomRid
                                AND @sStartDate <= wDate AND wDate < @sEndDate
                                
                            GROUP BY wDate, wRoomRid
                        ),
                        tResult AS (
                            SELECT ahd.wRoomRid, 
                                   ahd.wDate,
                                   ahd.wRoomPrice,
                                   ahd.wBreakfastPrice,
                                   ahd.wRoomCost,
                                   ahd.wCurrCode
                            FROM tHotelRoomDaily AS hrd
                            INNER JOIN dbo.eAllotmentHotelDaily AS ahd ON ahd.RowId = hrd.RowID
                        )

                        SELECT @sTotalAmount = SUM(wRoomPrice + wBreakfastPrice) FROM tResult;

                        UPDATE dr 
                        SET dr.wTotalAmt = ISNULL(@sTotalAmount, 0) * (dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty)
                        FROM dbo.eDeptReqRoom dr
                        WHERE dr.RowID = @sRowID;
                       ------------------------END 更新預訂金額-------------------------------

                        -- 更新sub record
                        SET @pProcessXML =  (
                            SELECT RowID            = dr.RowID ,
                                   wDeptReqRoomRid  = dr.wDeptReqRoomRid,
                                   wHotelRid        = dr.wHotelRid,
                                   wRoomRid         = dr.wRoomRid,
                                   wBigBedQty       = dr.wBigBedQty,	
                                   wTwinBedQty      = dr.wTwinBedQty,  
                                   wSuiteRoom1Qty   = dr.wSuiteRoom1Qty,
                                   wSuiteRoom2Qty   = dr.wSuiteRoom2Qty,
                                   wSuiteRoom3Qty   = dr.wSuiteRoom3Qty,
                                   wDayOfStay       = dr.wDayOfStay,
                                   wStartDate       = dr.wStartDate,
                                   wEndDate         = dr.wEndDate,
                                   wStatus          = dr.wStatus,
                                   wRepStatus       = dr.wRepStatus,
                                   wDeptStatus      = dr.wDeptStatus,
                                   wIsApproved      = dr.wIsApproved,
                                   wTotalAmount     = ISNULL(@sTotalAmount, 0) * (dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty),
                                   wBookingRid      = dr.wBookingRid,
                                   wRemark          = dr.wRemark,
                                   wCancelReason    = dr.wCancelReason,
                                   wCrtDt           = @sNow,
                                   wCrtBy           = dr.wCrtBy,
                                   wUpdDt           = @sNow,
                                   wUpdBy           = dr.wUpdBy
                            FROM #sDataSet_SetDeptReqRoomDetails tmp
                            INNER JOIN dbo.eDeptRespRoom dr ON dr.wDeptReqRoomRid = tmp.RowID
                            WHERE wRowNum = @sRuningIndex
                            FOR XML RAW('Record'), ROOT('DataSet')
                        );

                        INSERT INTO @vResult EXEC [spa].[SetDeptResponseRoom] @pProcessXML, 'U', @pMainCompNo, @sErrCode OUTPUT, @sErrMsg OUTPUT;

                        ------------------------------------------------------------------------------------------------------
                        -- 把記錄標識為“新記錄”: wIsNewReqRoom = 'Y'
                        -- SetDeptResponseRoom 自動把記錄標識為“已處理”: wIsNewReqRoom = 'N'
                        --UPDATE dr
                        --SET  dr.wIsNewReqRoom = 'Y'
                        --FROM dbo.eDeptReqRoom dr
                        --INNER JOIN #sDataSet_SetDeptReqRoomDetails tmp ON tmp.RowID = dr.RowID
                        --WHERE wRowNum = @sRuningIndex
                    END;

                    SET @sRuningIndex = @sRuningIndex + 1;
                END;
                */
                ------------------------------------------------------------------------------
            END;
            
            IF @pActionType = 'D'
            BEGIN
                UPDATE dr
                SET wStatus = 'T' ,
                    wUpdDt = @sNow,
                    wUpdBy = tmp.wUpdBy
                FROM dbo.eDeptReqRoom dr
                INNER JOIN #sDataSet_SetDeptReqRoomDetails tmp ON tmp.RowID = dr.RowID
                
                -- 刪掉所有回覆
                UPDATE drr
                SET wStatus = 'T' ,
                    wUpdDt = @sNow,
                    wUpdBy = tmp.wUpdBy
                FROM dbo.eDeptRespRoom drr
                INNER JOIN #sDataSet_SetDeptReqRoomDetails tmp ON tmp.RowID = drr.wDeptReqRoomRid
                WHERE drr.wStatus = 'A';

                -- 斷開訂務需求關聯
                UPDATE rb
                SET rb.wReqStatus = 'DL',
                    wUpdDt = @sNow,
                    wUpdBy = tmp.wUpdBy
                FROM dbo.eReqBooking rb
                INNER JOIN #sDataSet_SetDeptReqRoomDetails tmp ON tmp.RowID = rb.wRefRid
                WHERE rb.wStatus = 'A' AND rb.wBookingType = 'HOTEL' AND rb.wRefTable = 'eDeptReqRoom';

                -- 2019-04-12：OP#25956, Write Action Log
                DECLARE @vDeptRespRoomXML XML;

                SET @vDeptRespRoomXML = (
                    SELECT drr.RowID
                    FROM dbo.eDeptRespRoom drr WITH(NOLOCK)
                    INNER JOIN #sDataSet_SetDeptReqRoomDetails tmp ON tmp.RowID = drr.wDeptReqRoomRid
                    WHERE drr.wUpdDt = @sNow
                        AND drr.wUpdBy = tmp.wUpdBy
                    FOR XML RAW('Record'), ROOT('DataSet')
                );

                EXEC spa.SetDeptRespRoomChange @pDeptRespRoomXML = @vDeptRespRoomXML,
                                               @pMainCompNo      = @pMainCompNo,
                                               @pReturnResult    = 'N',
                                               @pErrCode         = @sErrCode OUTPUT,
                                               @pErrMsg          = @sErrMsg OUTPUT;
            END;

            -- 同步狀態到訂務需求eReqBooking.wReqStatus
            ----------------------------------------------------------------------------------
            SET @pXML = (
                SELECT  wDeptReqRoomRid = RowID, 
                        wUpdBy, 
                        wFollowDeptCd = wDeptFollowedCode, 
                        wFollowUserRid = wStaffFollowedRid 
                    FROM #sDataSet_SetDeptReqRoomDetails 
                FOR XML RAW('Record'), ROOT('DataSet')
            );

            IF @pActionType IN ('U', 'D') AND @pXML IS NOT NULL
                EXEC util.RecalReqBookingHotelStatus @pXML = @pXML, @pMainCompNo = @pMainCompNo, @pErrCode = @sErrCode OUTPUT, @pErrMsg = @sErrMsg OUTPUT;
            
            ----------------------------------------------------------------------------------
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
                SELECT RowID, wRequestNo FROM #sDataSet_SetDeptReqRoomDetails;
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
	
        IF OBJECT_ID('tempdb..#sDataSet_SetDeptReqRoomDetails') IS NOT NULL
            DROP TABLE #sDataSet_SetDeptReqRoomDetails;
    END;