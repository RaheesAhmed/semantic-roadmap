
CREATE PROCEDURE [spq].[GetDeptRequestRoomLstByAgentCode]
    @pAgentCodeIn VARCHAR(30),
    @pLangCd VARCHAR(10) = 'zh-TW',
    @pPageSize INT = 100,
    @pPageNum INT = 1 
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sReqStatus     VARCHAR(20),
            @sRollingAmt    NUMERIC(18,4);

    SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
    SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
    SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 100);
    SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
   
    WITH tResult AS (
        SELECT 
            dr.RowID,
            dr.wRequestNo,
            dr.wAgentCodeIn,
            wHotelName = h.wName,
            wRoomName = hr.wName,
            wRoomQty = dr.wBigBedQty + dr.wTwinBedQty + dr.wSuiteRoom1Qty + dr.wSuiteRoom2Qty + dr.wSuiteRoom3Qty,
            dr.wDayOfStay,
            dr.wStartDate,
            dr.wEndDate,
            dr.wRemark,
            dr.wIsCancel,
            wReqStatus = @sReqStatus,
            wTotalAmt = dr.wTotalAmt,
            wRollingAmt = @sRollingAmt,
            wFollowDept = CASE dr.wDeptFollowedCode WHEN 'DEVELOP'   THEN 'MD'
                                                    WHEN 'ROOM'      THEN 'CS'
                                                    WHEN 'HOUSEKEEPER' THEN 'VIP'
                                                    ELSE NULL
                          END,
            wFollowedUsr = fu.wCName,
            dr.wCrtDt,
            dr.wUpdDt
        FROM dbo.eDeptReqRoom AS dr WITH(NOLOCK)
        LEFT JOIN dbo.mHotel AS h ON h.RowID = dr.wHotelRid 
        LEFT JOIN dbo.mHotelRoom AS hr ON hr.RowID = dr.wRoomRid
        LEFT JOIN RollsMary.dbo.mUsr AS fu ON fu.RowID = dr.wStaffFollowedRid
        WHERE (@pAgentCodeIn = dr.wAgentCodeIn )
            AND dr.wStatus = 'A'
	),
	tCount AS (
        SELECT wRecordCount = COUNT(1) FROM tResult
    )

    SELECT
        tResult.*, 
        wRecordCount
    INTO #vResult
    FROM tResult, tCount
    ORDER BY wCrtDt DESC
    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
    FETCH NEXT @pPageSize ROWS ONLY
    OPTION (RECOMPILE );

    IF EXISTS (SELECT 1 FROM #vResult)
    BEGIN
        -- 完成狀態（計算得出）
        ------------------------------------------------------------------------------------------
        DECLARE @vStatusMap AS TABLE(
            wStatus VARCHAR(20),
            wMapValue INT,
            PRIMARY KEY(wStatus, wMapValue)
        );
        INSERT INTO @vStatusMap(
            wStatus,
            wMapValue
        )
        SELECT  wStatus     = wCode, 
                wMapValue   = wSeqNo
        FROM dbo.mLookUp
        WHERE wType = 'DEPTROOM_RESPONSE_STATUS' AND wLangCd = 'zh-TW';
        
        SELECT
            dr.wDeptReqRoomRid,
            wRepStatus = ( SELECT TOP(1) wStatus FROM @vStatusMap WHERE wMapValue = MIN(map.wMapValue))
        INTO #vRepStatus
        FROM dbo.eDeptRespRoom AS dr WITH(NOLOCK)
        INNER JOIN #vResult AS r ON r.RowID = dr.wDeptReqRoomRid
        INNER JOIN @vStatusMap AS map ON dr.wRepStatus = map.wStatus
        WHERE dr.wDeptReqRoomRid > 0 AND dr.wStatus = 'A'
        GROUP BY dr.wDeptReqRoomRid;   
        
        UPDATE r
        SET r.wReqStatus = ISNULL(IIF(rs.wRepStatus = 'CL' AND r.wIsCancel = 'Y', 'CL', NULLIF(rs.wRepStatus, 'CL')), 'P') -- 當所有sub record變成取消且main record要求取消，此時main record status = 'CL'，否則如果是'CL'自動變成'P'
        FROM #vResult AS r
        LEFT JOIN #vRepStatus AS rs ON r.RowID = rs.wDeptReqRoomRid
        ------------------------------------------------------------------------------------------

        -- 入住期間轉碼數量
        ------------------------------------------------------------------------------------------
        DECLARE @sRowID BIGINT;

        -- 戶口轉碼日期
        DECLARE @vRollingDate TABLE(wDate DATE PRIMARY KEY);

        INSERT INTO @vRollingDate
        SELECT DISTINCT wDate = DATEADD(DAY, spt.number, r.wStartDate)
        FROM #vResult r
        INNER JOIN master.dbo.spt_values spt ON 1 = 1
        WHERE spt.type = 'P' AND spt.number <= r.wDayOfStay;

        -- 獲取戶口列表的所有下線
        DECLARE @vRollingAgent TABLE (
            wAgentCodeIn VARCHAR(14),
            wEffectYearMth VARCHAR(14),
            wExpireYearMth VARCHAR(14),
            PRIMARY KEY(wAgentCodeIn, wEffectYearMth, wExpireYearMth)
        );

        INSERT INTO @vRollingAgent(wAgentCodeIn, wEffectYearMth, wExpireYearMth)
        SELECT DISTINCT 
            wAgentCodeIn,
            wEffectYearMth,
            wExpireYearMth
        FROM RollsMary.dbo.mAgentLevel
        WHERE wLvlAgentCodeIn = @pAgentCodeIn
        
        -- 戶口每天轉碼
        SELECT
            rd.wDate,
            wRollingHKD = SUM(ISNULL(mabrd.wRollingAPlayHKD + mabrd.wRollingBPlayHKD, 0))
        INTO #vRollingDaily
        FROM RollsMary.dbo.mAgentBalRollingDay mabrd
        INNER JOIN @vRollingAgent ra ON ra.wAgentCodeIn = mabrd.wAgentCodeIn
        INNER JOIN @vRollingDate rd ON rd.wDate = mabrd.wDate 
        WHERE ra.wEffectYearMth <= (mabrd.wYearMth)
            AND (mabrd.wYearMth <= ra.wExpireYearMth OR ISNULL(ra.wExpireYearMth, '') = '')
        GROUP BY rd.wDate
        OPTION(RECOMPILE);

        --DROP TABLE #vRollingDaily;

        --SELECT  ert.wAgentCodeIn, ertd.wDate, wRollingHKD = SUM(ertd.wRollingHKD)
        --INTO #vRollingDaily1
        --FROM Rollsmary.dbo.eRollTran ert
        --INNER JOIN Rollsmary.dbo.eRollTranDtl ertd ON ertd.wTranNo = ert.wTranNo
        --INNER JOIN @vRollingAgent ra ON ra.wAgentCodeIn = ert.wAgentCodeIn
        --INNER JOIN @vRollingDate rd ON 1 = 1 
        --WHERE ertd.wDate = rd.wDate
        --    AND ra.wEffectYearMth <= (ertd.wYear+ertd.wMonth)
        --    AND ((ertd.wYear+ertd.wMonth) <= ra.wExpireYearMth OR ISNULL(ra.wExpireYearMth, '') = '')
        --GROUP BY ert.wAgentCodeIn, ertd.wDate
        --OPTION(RECOMPILE);

        --SELECT * FROM #vRollingDaily1;

        --DROP TABLE #vRollingDaily1;

        DECLARE sCURSOR CURSOR FOR SELECT RowID FROM #vResult;
        OPEN sCURSOR;
        FETCH NEXT FROM sCURSOR INTO @sRowID;
        WHILE @@fetch_status = 0
        BEGIN
            SELECT @sRollingAmt = SUM(ISNULL(rd.wRollingHKD, 0))
            FROM #vResult r
            LEFT JOIN #vRollingDaily rd ON 1 = 1
            WHERE r.RowID = @sRowID
                AND rd.wDate BETWEEN r.wStartDate AND r.wEndDate;
            
            UPDATE #vResult SET wRollingAmt = ISNULL(@sRollingAmt, 0) / 10000 WHERE RowID = @sRowID;
                 
            FETCH NEXT FROM sCURSOR INTO @sRowID;
        END;
        CLOSE sCURSOR;
        DEALLOCATE sCURSOR;
        ------------------------------------------------------------------------------------------
    END;

    SELECT * FROM #vResult;

    IF OBJECT_ID('tempdb..#vRepStatus') IS NOT NULL
        DROP TABLE #vRepStatus;

    IF OBJECT_ID('tempdb..#vRollingDaily') IS NOT NULL
        DROP TABLE #vRollingDaily;

    IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
        DROP TABLE #vResult;
END;