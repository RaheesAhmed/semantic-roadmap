CREATE PROC [test].[GetReqBookingLst]
    @pXML           XML,
    @pSort          VARCHAR(100),
    @pLangCd        VARCHAR(10) = 'zh-TW',
    @pPageSize      INT = 20,
    @pPageNum       INT = 1
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sAgentPortrait VARBINARY(MAX);

        DECLARE @pAgentCodeIn   NVARCHAR(14),
                @pBookingType   VARCHAR(50),
                @pReqUser       NVARCHAR(50),
                @pReqDeptCd     VARCHAR(30),
                @pReqStatus     VARCHAR(10),
                @pStartDate     DATE,
                @pEndDate       DATE;

        SELECT  @pAgentCodeIn   = T.tmp.value('@wAgentCodeIn',  'NVARCHAR(14)'),
                @pBookingType   = T.tmp.value('@wBookingType',  'VARCHAR(50)'),
                @pReqUser       = T.tmp.value('@wReqUser',      'NVARCHAR(50)'),
                @pReqDeptCd     = T.tmp.value('@wReqDeptCd',    'VARCHAR(30)'),
                @pReqStatus     = T.tmp.value('@wReqStatus',    'VARCHAR(10)'),
                @pStartDate     = T.tmp.value('@wStartDate',    'DATE'),
                @pEndDate       = T.tmp.value('@wEndDate',      'DATE')
        FROM @pXML.nodes('DataSet/Record') T(tmp);
        
        SET @pAgentCodeIn   = NULLIF(@pAgentCodeIn, '');
        SET @pBookingType   = NULLIF(@pBookingType, '');
        SET @pReqUser       = NULLIF(@pReqUser, '');
        SET @pReqDeptCd     = NULLIF(@pReqDeptCd, '');
        SET @pReqStatus     = NULLIF(@pReqStatus, '');
        SET @pStartDate     = ISNULL(@pStartDate, '0001-01-01');
        SET @pEndDate       = ISNULL(@pEndDate, '9999-12-31');
        SET @pSort          = ISNULL(@pSort, '');
        SET @pLangCd        = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pPageSize      = ISNULL(@pPageSize, 20);
        SET @pPageNum       = ISNULL(@pPageNum, 1);

        ;WITH tReqBookingHotel AS (
            SELECT  rbh.RowID,
                    rbh.wReqBookingRid,
                    wRemark = CONCAT(N'酒店房間：', h.wName, 
                                    IIF(rbh.wBigBedRoomQty > 0, N' 大床房型x' + CONVERT(VARCHAR(10), rbh.wBigBedRoomQty), ''),
                                    IIF(rbh.wTwinBedRoomQty > 0, N' 雙床房型x' + CONVERT(VARCHAR(10), rbh.wTwinBedRoomQty), ''),
                                    IIF(rbh.wSuiteRoom1Qty > 0, N' 雙床房型x' + CONVERT(VARCHAR(10), rbh.wSuiteRoom1Qty), ''),
                                    IIF(rbh.wSuiteRoom2Qty > 0, N' 雙床房型x' + CONVERT(VARCHAR(10), rbh.wSuiteRoom2Qty), ''),
                                    IIF(rbh.wSuiteRoom3Qty > 0, N' 雙床房型x' + CONVERT(VARCHAR(10), rbh.wSuiteRoom3Qty), ''),
                                    CHAR(10),
                                    N'入住及退房日期：', FORMAT(rbh.wCheckInDate, 'yyyy-MM-dd'), N'至', FORMAT(rbh.wCheckOutDate, 'yyyy-MM-dd'), N' (', CONVERT(VARCHAR(10), DATEDIFF(DAY, rbh.wCheckInDate, rbh.wCheckOutDate)), N'天)',
                                    CHAR(10),
                                    N'備註：', rbh.wRemark
                                )
            FROM dbo.eReqBookingHotel rbh
            INNER JOIN dbo.mHotel h ON h.RowID = rbh.wHotelRid
            WHERE @pStartDate <= @pEndDate 
                AND NOT ( @pStartDate >= rbh.wCheckOutDate OR @pEndDate < rbh.wCheckInDate )
        ),
        tResult AS (
            SELECT rb.RowID,
                   ma.wAgentCodeIn,
                   ma.wAgentCode_Display,
                   wAgentCName = ma.wCName,
                   wAgentEName = ma.wEName,
                   wAgentNickName = ma.wNickName,
                   wAgentIdentity = CONVERT(NVARCHAR(50), N''),     -- 身份
                   wAgentIdentityColor = CONVERT(VARCHAR(7), ''),   -- 身份顏色
                   wAgentLevel = CONVERT(VARCHAR(30), ''), -- 戶口星級(HIGHLY_VALUED,STAR)
                   wAgentPortrait = @sAgentPortrait,
                   wBookingType = CASE rb.wBookingType WHEN 'HOTEL' THEN N'酒店訂務'
                                                       ELSE N'' END,
                   wReqUserName = CONCAT(ISNULL(req_mu.wCName, ''), IIF(ISNULL(req_mu.wCName, '') = '' OR ISNULL(req_mu.wName, '') = '', '', CHAR(10)), ISNULL(req_mu.wName, '')),
                   wReqUsrTel = req_mu.wPrivateTel, -- 電話號
                   wReqUsrTelExt = req_mu.wTelExt, -- 分機號
                   wReqUsrTelCountryCd = req_mu.wPrivateTelCountryCode, -- 區號
                   wReqDeptName = IIF(@pLangCd = 'en-GB', d.wEName, d.wCName),
                   wFollowUserName = CONCAT(ISNULL(fol_mu.wCName, ''), IIF(ISNULL(fol_mu.wCName, '') = '' OR ISNULL(fol_mu.wName, '') = '', '', CHAR(10)), ISNULL(fol_mu.wName, '')),
                   wRemark = CONCAT(IIF(ISNULL(rb.wRefNo, '') = '', '', N'需求號碼：' + rb.wRefNo + CHAR(10)), rbh.wRemark),
                   rb.wReqStatus,
                   rb.wCrtDt,
                   rb.wUpdDt
            FROM dbo.eReqBooking rb
            INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = rb.wAgentCodeIn
            LEFT JOIN RollsMary.dbo.mUsr req_mu ON req_mu.RowID = rb.wReqUserRid
            LEFT JOIN RollsMary.dbo.mUsr fol_mu ON fol_mu.RowID = rb.wFollowUserRid
            LEFT JOIN RollsMary.dbo.mDepartment d ON d.wCode = rb.wReqDeptCd AND d.wUserLineGrp = ''
            LEFT JOIN tReqBookingHotel rbh ON rbh.wReqBookingRid = rb.RowID
            WHERE rb.wStatus = 'A'
                AND (@pAgentCodeIn IS NULL OR ma.wAgentCode = @pAgentCodeIn Or ma.wAgentCode_Old = @pAgentCodeIn Or ma.wAgentCode_Src = @pAgentCodeIn Or ma.wAgentCode_Display = @pAgentCodeIn)
                AND (@pBookingType IS NULL OR @pBookingType = rb.wBookingType)
                AND (@pReqUser IS NULL OR @pReqUser = req_mu.wCName OR @pReqUser = req_mu.wName)
                AND (@pReqDeptCd IS NULL OR @pReqDeptCd = rb.wReqDeptCd)
                AND (@pReqStatus IS NULL OR @pReqStatus = rb.wReqStatus)
                AND rbh.RowID IS NOT NULL
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT RowID,
               wAgentCodeIn,
               wAgentCode_Display,
               wAgentCName,
               wAgentEName,
               wAgentNickName,
               wAgentIdentity,
               wAgentIdentityColor,
               wAgentLevel,
               wAgentPortrait,
               wBookingType,
               wReqUserName,
               wReqUsrTel = ISNULL(wReqUsrTel, ''),
               wReqUsrTelExt = ISNULL(wReqUsrTelExt, ''),
               wReqUsrTelCountryCd = ISNULL(wReqUsrTelCountryCd, ''),
               wReqDeptName,
               wFollowUserName,
               wRemark,
               wReqStatus,
               wCrtDt = FORMAT(wCrtDt, 'yyyy-MM-dd HH:mm:ss'),
               wUpdDt = FORMAT(wUpdDt, 'yyyy-MM-dd HH:mm:ss'), 
               wRecordCount
        INTO #vResult
        FROM tResult, tCount
        ORDER BY tResult.wCrtDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION (RECOMPILE );

        -------------------------------戶口身份--------------------------------
        DECLARE @vAgentXML XML;

        DECLARE @vAgentType TABLE(
            wCode       VARCHAR(30) PRIMARY KEY,
            wTitle      NVARCHAR(50),
            wBackground CHAR(7),
            wForeground CHAR(7),
            wSeqNo      INT
        );
        INSERT INTO @vAgentType SELECT * FROM dbo.fnGetAgentType(@pLangCd);

        CREATE TABLE #vAgentIdentity (
            wAgentCodeIn    VARCHAR(14) PRIMARY KEY,
            wShareLevel     INT,
            wAgentLevel     INT,
            wAgentType      VARCHAR(15),
            wDirectCredit   CHAR(1),
            wIsDownLevel    CHAR(1),
            wIsCapital      CHAR(1),
            wIsCredit       CHAR(1),
            wAgentIdentity  VARCHAR(20)
        );
        
        SET @vAgentXML = ( SELECT wAgentCodeIn FROM #vResult GROUP BY wAgentCodeIn FOR XML RAW('Record'), ROOT('DataSet') );

        INSERT INTO #vAgentIdentity EXEC RollsMary.spq.GetAgentIdentity @pXML = @vAgentXML;
        
        UPDATE r
        SET wAgentIdentity = vat.wTitle,
            wAgentIdentityColor = vat.wBackground
        FROM #vResult r
        INNER JOIN #vAgentIdentity vai ON vai.wAgentCodeIn = r.wAgentCodeIn
        INNER JOIN @vAgentType vat ON vat.wCode = vai.wAgentIdentity
        -------------------------------戶口身份--------------------------------

        ---------------------------------星級----------------------------------
        -- 星級優先級排列
        DECLARE @vAgentLevelMap TABLE (wType VARCHAR(30), wMapValue INT, PRIMARY KEY(wType, wMapValue));
        INSERT INTO @vAgentLevelMap (wType, wMapValue) VALUES ('HIGHLY_VALUED', 1), ('STAR', 2);

        SELECT  ai.wAgentCodeIn, 
                wAgentLevel = (SELECT TOP(1) wType FROM @vAgentLevelMap WHERE wMapValue = MIN(map.wMapValue))
        INTO #vAgentLevel
        FROM RollsMary.dbo.mAgentIdentity ai
        INNER JOIN @vAgentLevelMap map ON map.wType = ai.wType
        INNER JOIN #vResult r ON r.wAgentCodeIn = ai.wAgentCodeIn
        WHERE ai.wValue = 'Y'
        GROUP BY ai.wAgentCodeIn;

        UPDATE r
        SET wAgentLevel = ISNULL(al.wAgentLevel, '')
        FROM #vResult r
        LEFT JOIN #vAgentLevel al ON al.wAgentCodeIn = r.wAgentCodeIn;
        ---------------------------------星級----------------------------------

        -------------------------------戶口頭像--------------------------------
        SELECT d.RowID, d.wAgentCodeIn
        INTO #vDocument
        FROM (
            SELECT  RowNum = ROW_NUMBER() OVER(PARTITION BY wRefRID ORDER BY wUpdDt DESC),
                    ed.RowID,
                    r.wAgentCodeIn
            FROM RollsMary_Doc.dbo.eDocument ed
            INNER JOIN (SELECT wAgentCodeIn FROM #vResult GROUP BY wAgentCodeIn) r ON r.wAgentCodeIn = ed.wRefRID AND ed.wRefTable = 'mAgent'
            WHERE wStatus = 'A' AND wCategory = 'AGENT' AND wType = 'PHOTO' AND ed.wSizeType = 'S'
        ) AS d WHERE d.RowNum = 1;

        UPDATE r
        SET r.wAgentPortrait = ed.wFileData
        FROM #vResult r
        INNER JOIN #vDocument vd ON vd.wAgentCodeIn = r.wAgentCodeIn
        INNER JOIN RollsMary_Doc.dbo.eDocument ed ON ed.RowID = vd.RowID;
        -------------------------------戶口頭像--------------------------------

        SELECT * FROM #vResult;

        IF OBJECT_ID('tempdb..#vAgentIdentity') IS NOT NULL
            DROP TABLE #vAgentIdentity;

        IF OBJECT_ID('tempdb..#vAgentLevel') IS NOT NULL
            DROP TABLE #vAgentLevel;

        IF OBJECT_ID('tempdb..#vDocument') IS NOT NULL
            DROP TABLE #vDocument;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END