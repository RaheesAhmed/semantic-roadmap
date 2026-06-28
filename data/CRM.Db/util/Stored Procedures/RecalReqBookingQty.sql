CREATE PROC [util].[RecalReqBookingQty]
    @pLatestTime    DATETIME2(7) = NULL,
    @pXML           XML = NULL
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @pAgentCodeIn   NVARCHAR(14),
                @pBookingType   VARCHAR(50),
                @pReqUser       BIGINT,
                @pReqDeptCd     VARCHAR(30),
                @pReqStatus     VARCHAR(100),
                @pStartDate     DATE,
                @pEndDate       DATE,
                @pHotelRid      BIGINT;

        -- 訂務需求狀態多個拆分到Table
        DECLARE @vReqStatus TABLE ( wCode VARCHAR(10) PRIMARY KEY);

        DECLARE @sRecCount      INT = 0 ,
                @sRuningIndex   INT = 1 ,
                @sProgressQty   INT = 0,
                @sUserRid       BIGINT,
                @vFilterXML     XML,
                @vXML           XML,
                @sToday         DATE = dbo.fnUTC8Now();

        -----------------------------------------------------------------------------------------
        CREATE TABLE #vUser ( RowID BIGINT PRIMARY KEY );
        INSERT INTO #vUser (RowID)
        SELECT RowID FROM (
            SELECT RowID = T.tmp.value('@wUserRid', 'BIGINT')
            FROM @pXML.nodes('DataSet/Record') T(tmp)
        ) tmp WHERE ISNULL(RowID, 0) > 0 GROUP BY RowID;

        -- 只需要計算有房務部權限的未處理數量
        -----------------------------------------------------------------------------------------
        CREATE TABLE #vReqBookingFilterLog ( RowNum INT IDENTITY(1, 1), wUserRid BIGINT, wFilterXML NVARCHAR(1000), wProgressQty INT NOT NULL DEFAULT(0));
        INSERT INTO #vReqBookingFilterLog ( wUserRid, wFilterXML )
        SELECT  rbfl.wUserRid, 
                wFilterXML = CONVERT(NVARCHAR(1000), (SELECT rbfl.* FOR XML RAW('Record')))
        FROM dbo.eReqBookingFilterLog rbfl WITH(NOLOCK)
        INNER JOIN RollsMary.dbo.mUsr mu WITH(NOLOCK) ON mu.RowID = rbfl.wUserRid
        INNER JOIN RollsMary.dbo.mRoleFunction rf WITH(NOLOCK) ON rf.wRoleCd = mu.wRoleCd
        LEFT JOIN #vUser u ON u.RowID = rbfl.wUserRid
        WHERE rf.wStatus = 'A'
            AND rf.wActionType = 'CSROOM'
            AND rf.wFunctionCd = 'REQBOOKING'
            AND @sToday <= rbfl.wExpirationDate -- 過期佐嘅Filter唔再計算
            AND (@pXML IS NULL OR u.RowID IS NOT NULL); --如果有傳參數，只計算一個/多個指定Filter，否則計算所有Filter

        -- 刪掉非Filter字段（為了過濾相同的Filter，Filter相同不需要多次計算）
        -----------------------------------------------------------------------------------------
        SET @sRuningIndex = 1;
        SET @sRecCount = (SELECT COUNT(1) FROM #vReqBookingFilterLog);
        WHILE @sRuningIndex <= @sRecCount
        BEGIN
            SET @vFilterXML = (SELECT wFilterXML FROM #vReqBookingFilterLog WHERE RowNum = @sRuningIndex);
            SET @vFilterXML.modify('delete (/Record/@wUserRid)');
            SET @vFilterXML.modify('delete (/Record/@wProgressQty)');
            SET @vFilterXML.modify('delete (/Record/@wExpirationDate)');
            SET @vFilterXML.modify('delete (/Record/@wUpdDt)');
            
            UPDATE #vReqBookingFilterLog SET wFilterXML = CONVERT(NVARCHAR(1000), @vFilterXML) WHERE RowNum = @sRuningIndex;
            
            SET @sRuningIndex = @sRuningIndex + 1;
        END
        
        -- 過濾掉重複的，條件一樣的只需要Count一次
        -----------------------------------------------------------------------------------------
        CREATE TABLE #vFilter ( RowNum INT IDENTITY(1, 1), wXML XML );
        INSERT INTO #vFilter ( wXML )
        SELECT wFilterXML FROM #vReqBookingFilterLog GROUP BY wFilterXML;
        
        -- 逐條Filter計算訂務需求數量
        -----------------------------------------------------------------------------------------
        SET @sRuningIndex = 1;
        SET @sRecCount = (SELECT COUNT(1) FROM #vFilter);

        WHILE @sRuningIndex <= @sRecCount
        BEGIN
            SET @vFilterXML = (SELECT wXML FROM #vFilter WHERE RowNum = @sRuningIndex);

            SELECT  @pAgentCodeIn   = T.tmp.value('@wAgentCodeIn',      'NVARCHAR(14)'),
                    @pBookingType   = T.tmp.value('@wBookingType',      'VARCHAR(50)'),
                    @pReqUser       = T.tmp.value('@wReqUser',          'BIGINT'),
                    @pReqDeptCd     = T.tmp.value('@wReqDeptCd',        'VARCHAR(30)'),
                    @pReqStatus     = T.tmp.value('@wReqStatus',        'VARCHAR(100)'),
                    @pStartDate     = NULLIF(T.tmp.value('@wStartDate', 'VARCHAR(20)'), ''),
                    @pEndDate       = NULLIF(T.tmp.value('@wEndDate',   'VARCHAR(20)'), ''),
                    @pHotelRid      = T.tmp.value('@wHotelRid',         'BIGINT')
            FROM @vFilterXML.nodes('/Record') T(tmp);

            SET @pAgentCodeIn   = NULLIF(@pAgentCodeIn, '');
            SET @pBookingType   = NULLIF(@pBookingType, '');
            SET @pReqUser       = IIF(@pReqUser <= 0, NULL, @pReqUser);
            SET @pReqDeptCd     = NULLIF(@pReqDeptCd, '');
            SET @pReqStatus     = NULLIF(@pReqStatus, '');
            SET @pStartDate     = ISNULL(@pStartDate, '0001-01-01');
            SET @pEndDate       = ISNULL(@pEndDate, '9999-12-31');
            SET @pHotelRid      = IIF(@pHotelRid <= 0, NULL, @pHotelRid);

            -- 拆分訂務需求狀態
            SET @vXML = CONVERT(XML,'<DataSet><Record>' + REPLACE(ISNULL(@pReqStatus, ''), ',', '</Record><Record>') + '</Record></DataSet>')
            DELETE FROM @vReqStatus;
            INSERT INTO @vReqStatus (wCode)
            SELECT tmp.wCode FROM (
                SELECT wCode = T.tmp.value('.', 'VARCHAR(10)') 
                FROM @vXML.nodes('DataSet/Record') T(tmp)
            ) tmp WHERE NULLIF(tmp.wCode, '') IS NOT NULL GROUP BY tmp.wCode;

            ;WITH tReqBookingHotel AS (
                SELECT rbh.wReqBookingRid
                FROM dbo.eReqBookingHotel rbh WITH(NOLOCK)
                INNER JOIN dbo.mHotel h WITH(NOLOCK) ON h.RowID = rbh.wHotelRid
                WHERE rbh.wStatus = 'A'
                    AND (@pHotelRid IS NULL OR @pHotelRid = rbh.wHotelRid)
                    AND @pStartDate <= @pEndDate 
                    AND NOT ( @pStartDate >= rbh.wCheckOutDate OR @pEndDate < rbh.wCheckInDate )
            ),
            tResult AS (
                SELECT rbh.wReqBookingRid
                FROM dbo.eReqBooking rb WITH(NOLOCK)
                INNER JOIN RollsMary.dbo.mAgent ma WITH(NOLOCK) ON ma.wAgentCodeIn = rb.wAgentCodeIn
                LEFT JOIN tReqBookingHotel rbh ON rbh.wReqBookingRid = rb.RowID
                LEFT JOIN @vReqStatus rs ON rs.wCode = rb.wReqStatus
                WHERE rb.wStatus = 'A' AND rb.wReqStatus IN ('TP', 'P')
                    AND (@pAgentCodeIn IS NULL OR ma.wAgentCode = @pAgentCodeIn OR ma.wAgentCode_Old = @pAgentCodeIn OR ma.wAgentCode_Src = @pAgentCodeIn OR ma.wAgentCode_Display = @pAgentCodeIn)
                    AND (@pBookingType IS NULL OR @pBookingType = rb.wBookingType)
                    AND (@pReqUser IS NULL OR @pReqUser = rb.wReqUserRid)
                    AND (@pReqDeptCd IS NULL OR @pReqDeptCd = rb.wReqDeptCd)
                    AND (@pReqStatus IS NULL OR rs.wCode IS NOT NULL)
                    AND rbh.wReqBookingRid IS NOT NULL
            )

            SELECT @sProgressQty = COUNT(1) FROM tResult;

            UPDATE #vReqBookingFilterLog SET wProgressQty = ISNULL(@sProgressQty, 0) WHERE wFilterXML = CONVERT(NVARCHAR(1000), @vFilterXML);

            SET @sRuningIndex = @sRuningIndex + 1;
        END

        -- 重組XML，把計算結果寫加eReqBookingFilterLog，然後SignalR推送到Client
        -----------------------------------------------------------------------------------------
        SET @vXML = '<DataSet />';

        SET @sRuningIndex = 1;
        SET @sRecCount = (SELECT COUNT(1) FROM #vReqBookingFilterLog);
        WHILE @sRuningIndex <= @sRecCount
        BEGIN
            SELECT  @sUserRid       = wUserRid,  
                    @vFilterXML     = wFilterXML,
                    @sProgressQty   = wProgressQty
            FROM #vReqBookingFilterLog 
            WHERE RowNum = @sRuningIndex;

            SET @vFilterXML.modify('insert (attribute wUserRid {sql:variable("@sUserRid")}) into (/Record)[1]');
            SET @vFilterXML.modify('insert (attribute wProgressQty {sql:variable("@sProgressQty")}) into (/Record)[1]');

            SET @vXML.modify('insert sql:variable("@vFilterXML") into (DataSet)[1]')

            SET @sRuningIndex = @sRuningIndex + 1;
        END

        DECLARE @sErrCode INT,
                @sErrMsg NVARCHAR(200);

        EXEC spa.SetReqBookingFilterLog @pXML           = @vXML, 
                                        @pSetQty        = 'Y',
                                        @pReturnResult  = 'N',
                                        @pTestMode      = 0,
                                        @pErrCode       = @sErrCode OUTPUT,
                                        @pErrMsg        = @sErrMsg OUTPUT;

        -----------------------------------------------------------------------------------------
        IF OBJECT_ID('tempdb..#vUser') IS NOT NULL
            DROP TABLE #vUser;

        IF OBJECT_ID('tempdb..#vFilter') IS NOT NULL
            DROP TABLE #vFilter;

        IF OBJECT_ID('tempdb..#vReqBookingFilterLog') IS NOT NULL
            DROP TABLE #vReqBookingFilterLog;
    END