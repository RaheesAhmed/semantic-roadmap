
CREATE PROCEDURE [spq].[GetRollingWinLossForDeptRoom]
    @pAgentCodeIn       VARCHAR(14),
    @pDeptReqRoomRid    BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        -- dbml
        -----------------------------------------------------------------------
        --DECLARE @vResult TABLE (wResult XML);
        --SELECT * FROM @vResult
        -----------------------------------------------------------------------

        DECLARE @sNow DATETIME2(7) = dbo.fnUTC8Now(), --當前時間
                @sCompNo INT; -- 場館

        DECLARE @vXML XML,
                @vResultXML XML;

        SET @sCompNo = (
            SELECT TOP(1) sc.wRollexCompNo 
            FROM dbo.eDeptReqRoom req 
            INNER JOIN dbo.mHotel h ON h.RowID = req.wHotelRid 
            LEFT JOIN dbo.mServiceCounter sc ON sc.RowID = h.wDebitServiceCounter
        );

        --獲取最近3個月
        --DECLARE @sPastThreeYearMonth VARCHAR(6); --當前時間往前數第3個月
        --SET @sPastThreeYearMonth = CONCAT(LEFT(CAST(DATEADD(MONTH, -2,@sNow) AS VARCHAR(10)), 4), SUBSTRING(CAST(DATEADD(MONTH, -2,@sNow) AS VARCHAR(10)), 6, 2));
        --SET @vXML = (
        --    SELECT  wAgentCodeIn = @pAgentCodeIn,
        --            wCompNo      = @sCompNo,
        --            wYearMonth   = CONCAT(wYear, wMonth)
        --    FROM RollsMary.dbo.mSettlePeriod
        --    WHERE wCompNo = 95
        --        AND (wYear + wMonth) >= @sPastThreeYearMonth
        --        AND wStartDate <= @sNow
        --    FOR XML RAW('Record'), ROOT('DataSet')
        --);

        SET @vXML = (
            SELECT  wAgentCodeIn = @pAgentCodeIn,
                    wCompNo      = @sCompNo,
                    wYearMonth   = tmp.wYearMonth
            FROM (
                SELECT  wYearMonth   = FORMAT(@sNow, 'yyyyMM')
                UNION
                SELECT  wYearMonth   = FORMAT(DATEADD(MONTH, -1, @sNow), 'yyyyMM')
                UNION
                SELECT  wYearMonth   = FORMAT(DATEADD(MONTH, -2, @sNow), 'yyyyMM')
            ) tmp
            FOR XML RAW('Record'), ROOT('DataSet')
        );

        -- SET @vXML = '<DataSet><Record wAgentCodeIn="1000010180" wYearMonth="201911"/></DataSet>'
        
        -- 集團、場館轉碼
        EXEC util.GetRollingAndWinLoss @pXML = @vXML,
                                       @pResultXML = @vResultXML OUTPUT;

        -- 消費積分

        SELECT wResult = @vResultXML;
    END