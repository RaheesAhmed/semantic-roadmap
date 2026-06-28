CREATE PROC [spq].[GetRptDeptRequestRoomSummary]
    @pEventRid  BIGINT,
    @pLangCd    VARCHAR(10),
    @pErrCode   INT OUTPUT,
    @pErrMsg    NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        ---------------------------------------------------------------------
        -- dbml
        --DECLARE @vResult TABLE(
        --    wDate               DATE NOT NULL,
        --    wHotelRid           BIGINT NOT NULL,
        --    wHotelName          NVARCHAR(200) NOT NULL,
        --    wEventName          NVARCHAR(200) NOT NULL,
        --    wTotalBigBedQty     INT NOT NULL,
        --    wTotalTwinBedQty    INT NOT NULL,
        --    wTotalSuiteRoom1Qty INT NOT NULL,
        --    wTotalSuiteRoom2Qty INT NOT NULL,
        --    wTotalSuiteRoom3Qty INT NOT NULL,
        --    wTotalRoomQty       INT NOT NULL
        --);

        --SELECT * FROM @vResult;
        ---------------------------------------------------------------------
        SET @pErrCode = 0;
        SET @pErrMsg = NULL;
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pEventRid = ISNULL(@pEventRid, 0);

        IF NULLIF(@pErrMsg, '') IS NULL AND @pEventRid <= 0
            SET @pErrMsg = N'特別事件不能為空.';

        IF NULLIF(@pErrMsg, '') IS NULL AND NOT EXISTS (SELECT 1 FROM dbo.mEvent WHERE RowID = @pEventRid)
            SET @pErrMsg = N'特別事件不存在.';

        IF NULLIF(@pErrMsg, '') IS NOT NULL
        BEGIN
            SET @pErrCode = 50001;
        END
        ELSE
        BEGIN
            DECLARE @sStartDate DATE,
                    @sEndDate   DATE,
                    @sDay       INT,
                    @sEventName NVARCHAR(200);

            DECLARE @vDay TABLE ( wDate DATE PRIMARY KEY);
            DECLARE @vMapDeptStatus TABLE(wDeptStatus VARCHAR(30) PRIMARY KEY);

            -- CS拒絶 --> CS_RJ，不達標 --> CS_UQ，員工入數出錯 --> CS_MM，客人取消 --> CL，客人取消(2) --> CL2，客人取消(3) --> CL3 >>不計
            INSERT INTO @vMapDeptStatus(wDeptStatus) VALUES('CB'), ('CS_AH'), ('CS_RA'), ('CS_RC'), ('CS_RU'), ('RA'), ('RC'), ('RU');

            SELECT @sStartDate = wStartDate, @sEndDate = wEndDate FROM dbo.mEvent WHERE RowID = @pEventRid;
            SET @sEventName = (SELECT TOP(1) CONCAT(wCode, ' - ', wName) FROM dbo.mEvent WHERE RowID = @pEventRid);

            -- 把日期範圍轉換成每一天
            IF @sStartDate IS NOT NULL AND @sEndDate IS NOT NULL
            BEGIN
                SET @sDay = DATEDIFF(DAY, @sStartDate, @sEndDate);

                INSERT INTO @vDay ( wDate )
                SELECT wDate = DATEADD(DAY, number, @sStartDate)
                FROM master.dbo.spt_values
                WHERE type = 'P' AND number <= @sDay ;
            END;
        
            SELECT d.wDate,
                   resp.wHotelRid,
                   wHotelName = IIF(@pLangCd = 'zh-TW', h.wName, h.wEname),
                   wEventName = @sEventName,
                   wTotalBigBedQty = SUM(resp.wBigBedQty),
                   wTotalTwinBedQty = SUM(resp.wTwinBedQty),
                   wTotalSuiteRoom1Qty = SUM(resp.wSuiteRoom1Qty),
                   wTotalSuiteRoom2Qty = SUM(resp.wSuiteRoom2Qty),
                   wTotalSuiteRoom3Qty = SUM(resp.wSuiteRoom3Qty),
                   wTotalRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
            FROM @vDay d
            CROSS JOIN dbo.eDeptRespRoom resp WITH(NOLOCK)
            INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = resp.wDeptReqRoomRid
            INNER JOIN @vMapDeptStatus ds ON ds.wDeptStatus = resp.wDeptStatus
            INNER JOIN dbo.mHotel h ON h.RowID = resp.wHotelRid
            WHERE resp.wStatus = 'A' AND req.wStatus = 'A'
                AND req.wEventRid = @pEventRid
                AND (resp.wStartDate <= d.wDate  AND d.wDate < resp.wEndDate)
            GROUP BY d.wDate, resp.wHotelRid, h.wName, h.wEname;
        END;
    END