CREATE PROC [spq].[GetReqBookingLst]
    @pXML           XML,
    @pSort          VARCHAR(100),
    @pLangCd        VARCHAR(10) = 'zh-TW',
    @pPageSize      INT = 20,
    @pPageNum       INT = 1
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sAgentPortrait VARBINARY(MAX),
                @sNow           DATETIME2(7) = dbo.fnUTC8Now();

        DECLARE @pAgentCodeIn   NVARCHAR(14),
                @pBookingType   VARCHAR(50),
                @pReqUser       BIGINT,
                @pReqDeptCd     VARCHAR(30),
                @pReqStatus     VARCHAR(100),
                @pStartDate     DATE,
                @pEndDate       DATE,
                @pHotelRid      BIGINT,
                @vXML           XML;

        DECLARE @vReqBooking_Status TABLE(wCode VARCHAR(10) PRIMARY KEY, wTitle NVARCHAR(50), wSeqNo INT, wFontColor VARCHAR(8));

        INSERT INTO @vReqBooking_Status (
            wCode,
            wTitle,
            wSeqNo,
            wFontColor
        )
        SELECT  wCode, 
                wTitle, 
                wSeqNo = ROW_NUMBER() OVER (ORDER BY wSeqNo),
                wFontColor = CASE wCode WHEN 'TP'    THEN '#4B8C00'
                                        WHEN 'P'     THEN '#F5A623'
                                        WHEN 'C'     THEN '#347BCC'
                                        WHEN 'RJ'    THEN '#D74153'
                                        WHEN 'CL'    THEN '#D74153'
                                        WHEN 'DL'    THEN '#D74153'
                                        ELSE '#000000' END
        FROM dbo.mLookUp WITH(NOLOCK) WHERE wType = 'REQBOOKING_STATUS' AND wLangCd = 'zh-TW';

        DECLARE @vReqStatus TABLE ( wCode VARCHAR(10) PRIMARY KEY);

        SELECT  @pAgentCodeIn   = T.tmp.value('@wAgentCodeIn',      'NVARCHAR(14)'),
                @pBookingType   = T.tmp.value('@wBookingType',      'VARCHAR(50)'),
                @pReqUser       = T.tmp.value('@wReqUser',          'BIGINT'),
                @pReqDeptCd     = T.tmp.value('@wReqDeptCd',        'VARCHAR(30)'),
                @pReqStatus     = T.tmp.value('@wReqStatus',        'VARCHAR(100)'),
                @pStartDate     = NULLIF(T.tmp.value('@wStartDate', 'VARCHAR(20)'), ''),
                @pEndDate       = NULLIF(T.tmp.value('@wEndDate',   'VARCHAR(20)'), ''),
                @pHotelRid      = T.tmp.value('@wHotelRid',         'BIGINT')
        FROM @pXML.nodes('DataSet/Record') T(tmp);
        
        SET @pAgentCodeIn   = NULLIF(@pAgentCodeIn, '');
        SET @pBookingType   = NULLIF(@pBookingType, '');
        SET @pReqUser       = IIF(@pReqUser <= 0, NULL, @pReqUser);
        SET @pReqDeptCd     = NULLIF(@pReqDeptCd, '');
        SET @pReqStatus     = NULLIF(@pReqStatus, '');
        SET @pStartDate     = ISNULL(@pStartDate, '0001-01-01');
        SET @pEndDate       = ISNULL(@pEndDate, '9999-12-31');
        SET @pHotelRid      = IIF(@pHotelRid <= 0, NULL, @pHotelRid);
        SET @pSort          = ISNULL(@pSort, '');
        SET @pLangCd        = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pPageSize      = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 20);
        SET @pPageNum       = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
        
        SET @vXML = CONVERT(XML,'<DataSet><Record>' + REPLACE(ISNULL(@pReqStatus, ''), ',', '</Record><Record>') + '</Record></DataSet>')

        INSERT INTO @vReqStatus (wCode)
        SELECT tmp.wCode FROM (
            SELECT wCode = T.tmp.value('.', 'VARCHAR(10)') 
            FROM @vXML.nodes('DataSet/Record') T(tmp)
        ) tmp WHERE NULLIF(tmp.wCode, '') IS NOT NULL GROUP BY tmp.wCode;

        ;WITH tReqBookingHotel AS (
            SELECT  rbh.RowID,
                    rbh.wReqBookingRid,
                    rbh.wGUID,
                    wDetail = CONCAT(N'酒店房間：', h.wName, 
                                    IIF(rbh.wBigBedRoomQty > 0, N' 大床房型x' + CONVERT(VARCHAR(10), rbh.wBigBedRoomQty), ''),
                                    IIF(rbh.wTwinBedRoomQty > 0, N' 雙床房型x' + CONVERT(VARCHAR(10), rbh.wTwinBedRoomQty), ''),
                                    IIF(rbh.wSuiteRoom1Qty > 0, N' 套房x' + CONVERT(VARCHAR(10), rbh.wSuiteRoom1Qty), ''),
                                    IIF(rbh.wSuiteRoom2Qty > 0, N' 套房2x' + CONVERT(VARCHAR(10), rbh.wSuiteRoom2Qty), ''),
                                    IIF(rbh.wSuiteRoom3Qty > 0, N' 套房3x' + CONVERT(VARCHAR(10), rbh.wSuiteRoom3Qty), ''),
                                    CHAR(10),
                                    N'入住及退房日期：', FORMAT(rbh.wCheckInDate, 'yyyy-MM-dd'), N'至', FORMAT(rbh.wCheckOutDate, 'yyyy-MM-dd'), N' (', CONVERT(VARCHAR(10), DATEDIFF(DAY, rbh.wCheckInDate, rbh.wCheckOutDate)), N'天)'   
                                ),
                    wRemark = CONCAT(N'備註：', rbh.wRemark)
            FROM dbo.eReqBookingHotel rbh WITH(NOLOCK)
            INNER JOIN dbo.mHotel h WITH(NOLOCK) ON h.RowID = rbh.wHotelRid
            WHERE rbh.wStatus = 'A'
                AND (@pHotelRid IS NULL OR @pHotelRid = rbh.wHotelRid)
                AND @pStartDate <= @pEndDate 
                AND NOT ( @pStartDate >= rbh.wCheckOutDate OR @pEndDate < rbh.wCheckInDate )
        ),
        tResult AS (
            SELECT rbh.wReqBookingRid,
                   wReqBookingGUID = CONVERT(VARCHAR(100), rb.wGUID),
                   wReqBookingHotelRid = rbh.RowID,
                   wReqBookingHotelGUID = CONVERT(VARCHAR(100), rbh.wGUID),
                   rb.wBookingType,
                   wBookingTypeName = CASE rb.wBookingType WHEN 'HOTEL' THEN N'酒店訂務'
                                                           ELSE N'' END,
                   ma.wAgentCodeIn,
                   ma.wAgentCode_Display,
                   wAgentCName = ma.wCName,
                   wAgentEName = ma.wEName,
                   wAgentNickName = ma.wNickName,
                   wAgentIdentity = CONVERT(NVARCHAR(50), ma.wAccountType),     -- 身份
                   wAgentIdentityColor = CONVERT(VARCHAR(7), ''),   -- 身份顏色
                   wAgentLevel = CONVERT(VARCHAR(30), ''), -- 戶口星級(HIGHLY_VALUED,STAR)
                   wAgentPortrait = @sAgentPortrait,
                   wReqUserName = CONCAT(ISNULL(req_mu.wCName, ''), IIF(ISNULL(req_mu.wCName, '') = '' OR ISNULL(req_mu.wName, '') = '', '', CHAR(10)), ISNULL(req_mu.wName, '')),
                   wReqUsrTel = req_mu.wPrivateTel, -- 電話號
                   wReqUsrTelExt = req_mu.wTelExt, -- 分機號
                   wReqUsrTelCountryCd = req_mu.wPrivateTelCountryCode, -- 區號
                   wReqDeptName = IIF(@pLangCd = 'en-GB', d.wEName, d.wCName),
                   wFollowUserName = CONCAT(ISNULL(fol_mu.wCName, ''), IIF(ISNULL(fol_mu.wCName, '') = '' OR ISNULL(fol_mu.wName, '') = '', '', CHAR(10)), ISNULL(fol_mu.wName, '')),
                   wDetail = CONCAT(IIF(ISNULL(rb.wRefNo, '') = '', '', N'需求號碼：' + rb.wRefNo + CHAR(10)), rbh.wDetail),
                   rbh.wRemark,
                   rb.wReqStatus,
                   wReqStatusName = ISNULL(rbs.wTitle, ''),
                   wReqStatusColor = ISNULL(rbs.wFontColor, '#000000'),
                   wReqStatusNo = ISNULL(rbs.wSeqNo, 0),
                   rb.wCrtDt,
                   rb.wUpdDt
            FROM dbo.eReqBooking rb WITH(NOLOCK)
            INNER JOIN RollsMary.dbo.mAgent ma WITH(NOLOCK) ON ma.wAgentCodeIn = rb.wAgentCodeIn
            LEFT JOIN RollsMary.dbo.mUsr req_mu WITH(NOLOCK) ON req_mu.RowID = rb.wReqUserRid
            LEFT JOIN RollsMary.dbo.mUsr fol_mu WITH(NOLOCK) ON fol_mu.RowID = rb.wFollowUserRid
            LEFT JOIN RollsMary.dbo.mDepartment d WITH(NOLOCK) ON d.wCode = rb.wReqDeptCd AND d.wUserLineGrp = ''
            LEFT JOIN tReqBookingHotel rbh ON rbh.wReqBookingRid = rb.RowID
            LEFT JOIN @vReqStatus rs ON rs.wCode = rb.wReqStatus
            LEFT JOIN @vReqBooking_Status rbs ON rbs.wCode = rb.wReqStatus
            WHERE rb.wStatus = 'A'
                AND (@pAgentCodeIn IS NULL OR ma.wAgentCode = @pAgentCodeIn Or ma.wAgentCode_Old = @pAgentCodeIn Or ma.wAgentCode_Src = @pAgentCodeIn Or ma.wAgentCode_Display = @pAgentCodeIn)
                AND (@pBookingType IS NULL OR @pBookingType = rb.wBookingType)
                AND (@pReqUser IS NULL OR @pReqUser = req_mu.RowID)
                AND (@pReqDeptCd IS NULL OR @pReqDeptCd = rb.wReqDeptCd)
                AND (@pReqStatus IS NULL OR rs.wCode IS NOT NULL)
                AND rbh.RowID IS NOT NULL
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT  RowNum = ROW_NUMBER() OVER (ORDER BY @sNow),
                wReqBookingRid,
                wReqBookingGUID,
                wReqBookingHotelRid,
                wReqBookingHotelGUID,
                wBookingType,
                wBookingTypeName,
                wAgentCodeIn,
                wAgentCode_Display,
                wAgentCName,
                wAgentEName,
                wAgentNickName,
                wAgentIdentity,
                wAgentIdentityColor,
                wAgentLevel,
                wAgentPortrait,
                wReqUserName,
                wReqUsrTel = ISNULL(wReqUsrTel, ''),
                wReqUsrTelExt = ISNULL(wReqUsrTelExt, ''),
                wReqUsrTelCountryCd = ISNULL(wReqUsrTelCountryCd, ''),
                wReqDeptName,
                wFollowUserName,
                wDetail,
                wRemark,
                wReqStatus,
                wReqStatusName,
                wReqStatusColor,
                wCrtDt = FORMAT(wCrtDt, 'yyyy-MM-dd HH:mm:ss'),
                wUpdDt = FORMAT(wUpdDt, 'yyyy-MM-dd HH:mm:ss'), 
                wRecordCount
        INTO #vResult
        FROM tResult, tCount
        ORDER BY CASE @pSort WHEN 'AgentCodeIn ASC'     THEN wAgentCode_Display END ASC,
                 CASE @pSort WHEN 'AgentCodeIn DESC'    THEN wAgentCode_Display END DESC,
                 CASE @pSort WHEN 'AgentName ASC'       THEN wAgentCName END ASC,
                 CASE @pSort WHEN 'AgentName DESC'      THEN wAgentCName END DESC,
                 CASE @pSort WHEN 'AgentIdentity ASC'   THEN wAgentIdentity END ASC,
                 CASE @pSort WHEN 'AgentIdentity DESC'  THEN wAgentIdentity END DESC,
                 CASE @pSort WHEN 'BookingType ASC'     THEN wBookingType END ASC,
                 CASE @pSort WHEN 'BookingType DESC'    THEN wBookingType END DESC,
                 CASE @pSort WHEN 'ReqDeptName ASC'     THEN wReqDeptName END ASC,
                 CASE @pSort WHEN 'ReqDeptName DESC'    THEN wReqDeptName END DESC,
                 CASE @pSort WHEN 'ReqUserName ASC'     THEN wReqUserName END ASC,
                 CASE @pSort WHEN 'ReqUserName DESC'    THEN wReqUserName END DESC,
                 CASE @pSort WHEN 'FollowUserName ASC'  THEN wFollowUserName END ASC,
                 CASE @pSort WHEN 'FollowUserName DESC' THEN wFollowUserName END DESC,
                 CASE @pSort WHEN 'ReqStatus ASC'       THEN wReqStatusNo END ASC,
                 CASE @pSort WHEN 'ReqStatus DESC'      THEN wReqStatusNo END DESC,
                 CASE @pSort WHEN 'CrtDt ASC'           THEN wCrtDt END ASC,
                 CASE @pSort WHEN 'CrtDt DESC'          THEN wCrtDt END DESC,
                 CASE @pSort WHEN ''                    THEN wCrtDt END DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION (RECOMPILE );
        
        ---------------------------------訂房數量-----------------------------------
        --;WITH tRequestRoom AS ( -- 需求數量
        --    SELECT wDeptReqRoomRid,
        --           wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        --    FROM dbo.eDeptRespRoom WITH(NOLOCK)
        --    WHERE wStatus = 'A'
        --        AND wRepStatus IN ('P', 'C', 'CL')
        --        AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        --    GROUP BY wDeptReqRoomRid
        --), tUnCompletedRoom AS ( -- 處理中房間數量
        --    SELECT wDeptReqRoomRid,
        --           wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        --    FROM dbo.eDeptRespRoom WITH(NOLOCK)
        --    WHERE wStatus = 'A' 
        --        AND wRepStatus = 'P' 
        --        AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        --    GROUP BY wDeptReqRoomRid
        --), tCancelledRoom AS ( -- 客人取消房間數量
        --    SELECT wDeptReqRoomRid,
        --           wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        --    FROM dbo.eDeptRespRoom WITH(NOLOCK)
        --    WHERE wStatus = 'A' 
        --        AND wRepStatus = 'CL' 
        --        AND wDeptStatus NOT IN ('CS_ST', 'CS_MM', 'CS_UQ')
        --    GROUP BY wDeptReqRoomRid
        --), tCompletedNotReqRoom AS ( -- 非需求酒店房間完成數量
        --    SELECT resp.wDeptReqRoomRid,
        --           wRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
        --    FROM dbo.eDeptRespRoom resp WITH(NOLOCK)
        --    INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = resp.wDeptReqRoomRid
        --    WHERE resp.wStatus = 'A' 
        --        AND resp.wRepStatus = 'C' 
        --        AND resp.wHotelRid <> req.wHotelRid 
        --        AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        --    GROUP BY wDeptReqRoomRid
        --), tCompletedReqRoom AS ( -- 需求酒店房間完成數量
        --    SELECT resp.wDeptReqRoomRid,
        --           wRoomQty = SUM(resp.wBigBedQty + resp.wTwinBedQty + resp.wSuiteRoom1Qty + resp.wSuiteRoom2Qty + resp.wSuiteRoom3Qty)
        --    FROM dbo.eDeptRespRoom resp WITH(NOLOCK)
        --    INNER JOIN dbo.eDeptReqRoom req WITH(NOLOCK) ON req.RowID = resp.wDeptReqRoomRid
        --    WHERE resp.wStatus = 'A' 
        --        AND resp.wRepStatus = 'C' 
        --        AND resp.wHotelRid = req.wHotelRid 
        --        AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        --    GROUP BY wDeptReqRoomRid
        --), tCompletedRoom AS ( -- 訂單已派房總數
        --    SELECT wDeptReqRoomRid,
        --           wRoomQty = SUM(wBigBedQty + wTwinBedQty + wSuiteRoom1Qty + wSuiteRoom2Qty + wSuiteRoom3Qty)
        --    FROM dbo.eDeptRespRoom WITH(NOLOCK)
        --    WHERE wStatus = 'A' 
        --        AND wRepStatus = 'C' 
        --        AND wDeptStatus NOT IN ('CS_ST', 'CS_MM')
        --    GROUP BY wDeptReqRoomRid
        --)

        --SELECT  r.wReqBookingRid,
        --        wRequestRoomQty         = CONVERT(VARCHAR(10), ISNULL(rr.wRoomQty, 0)), -- 需求數量
        --        wUnCompletedRoomQty     = CONVERT(VARCHAR(10), ISNULL(ucr.wRoomQty, 0)), -- 處理中房間數量
        --        wCancelledRoomQty       = CONVERT(VARCHAR(10), ISNULL(cr.wRoomQty, 0)), -- 客人取消房間數量
        --        wCompletedNotReqRoomQty = CONVERT(VARCHAR(10), ISNULL(cnrr.wRoomQty, 0)), -- 非需求酒店房間完成數量
        --        wCompletedReqRoomQty    = CONVERT(VARCHAR(10), ISNULL(crr.wRoomQty, 0)), -- 需求酒店房間完成數量
        --        wCompletedRoomQty       = CONVERT(VARCHAR(10), ISNULL(cdr.wRoomQty, 0)) -- 訂單已派房總數
        --INTO #vDeptReqRoomSummary
        --FROM #vResult r
        --INNER JOIN dbo.eReqBooking rb WITH(NOLOCK) ON rb.RowID = r.wReqBookingRid
        --LEFT JOIN tRequestRoom AS rr ON rr.wDeptReqRoomRid = rb.wRefRid
        --LEFT JOIN tUnCompletedRoom AS ucr ON ucr.wDeptReqRoomRid = rb.wRefRid
        --LEFT JOIN tCancelledRoom AS cr ON cr.wDeptReqRoomRid = rb.wRefRid
        --LEFT JOIN tCompletedNotReqRoom AS cnrr ON cnrr.wDeptReqRoomRid = rb.wRefRid
        --LEFT JOIN tCompletedReqRoom AS crr ON crr.wDeptReqRoomRid = rb.wRefRid
        --LEFT JOIN tCompletedRoom AS cdr ON cdr.wDeptReqRoomRid = rb.wRefRid
        --WHERE r.wBookingType = 'HOTEL' AND rb.wRefRid > 0;

        --UPDATE r
        --SET wReqStatusRemark = CONCAT(wUnCompletedRoomQty, '/', wCancelledRoomQty, '/', wCompletedNotReqRoomQty, '/', wCompletedReqRoomQty, '/', wRequestRoomQty)
        --FROM #vResult r
        --INNER JOIN #vDeptReqRoomSummary vsum ON vsum.wReqBookingRid = r.wReqBookingRid
        --WHERE r.wBookingType = 'HOTEL';
        ---------------------------------訂房數量-----------------------------------

        -------------------------------Old: 戶口身份--------------------------------
        --DECLARE @vAgentXML XML;

        --DECLARE @vAgentType TABLE(
        --    wCode       VARCHAR(30) PRIMARY KEY,
        --    wTitle      NVARCHAR(50),
        --    wBackground CHAR(7),
        --    wForeground CHAR(7),
        --    wSeqNo      INT
        --);
        --INSERT INTO @vAgentType SELECT * FROM dbo.fnGetAgentType(@pLangCd);

        --CREATE TABLE #vAgentIdentity (
        --    wAgentCodeIn    VARCHAR(14) PRIMARY KEY,
        --    wShareLevel     INT,
        --    wAgentLevel     INT,
        --    wAgentType      VARCHAR(15),
        --    wDirectCredit   CHAR(1),
        --    wIsDownLevel    CHAR(1),
        --    wIsCapital      CHAR(1),
        --    wIsCredit       CHAR(1),
        --    wAgentIdentity  VARCHAR(20)
        --);
        
        --SET @vAgentXML = ( SELECT wAgentCodeIn FROM #vResult GROUP BY wAgentCodeIn FOR XML RAW('Record'), ROOT('DataSet') );

        --INSERT INTO #vAgentIdentity EXEC RollsMary.spq.GetAgentIdentity @pXML = @vAgentXML;
        
        --UPDATE r
        --SET wAgentIdentity = vat.wTitle,
        --    wAgentIdentityColor = vat.wBackground
        --FROM #vResult r
        --INNER JOIN #vAgentIdentity vai ON vai.wAgentCodeIn = r.wAgentCodeIn
        --INNER JOIN @vAgentType vat ON vat.wCode = vai.wAgentIdentity
        -------------------------------Old: 戶口身份--------------------------------

        -------------------------------New: 戶口身份--------------------------------
        DECLARE @vAccountType TABLE(
            wCode       VARCHAR(30) PRIMARY KEY,
            wTitle      NVARCHAR(50),
            wBackground CHAR(7),
            wForeground CHAR(7),
            wSeqNo      INT
        );

        INSERT INTO @vAccountType (
            wCode,
            wTitle,
            wBackground,
            wForeground,
            wSeqNo
        )
        SELECT wCode, wTitle, wBackground, wForeground, wSeqNo FROM dbo.fnGetAgentAccountType(@pLangCd)

        UPDATE r
        SET wAgentIdentity = vat.wTitle,
            wAgentIdentityColor = vat.wBackground
        FROM #vResult r
        INNER JOIN @vAccountType vat ON vat.wCode = r.wAgentIdentity;
        -------------------------------New: 戶口身份--------------------------------

        ---------------------------------星級----------------------------------
        -- 星級優先級排列
        DECLARE @vAgentLevelMap TABLE (wType VARCHAR(30), wMapValue INT, PRIMARY KEY(wType, wMapValue));
        INSERT INTO @vAgentLevelMap (wType, wMapValue) VALUES ('HIGHLY_VALUED', 1), ('STAR', 2);

        SELECT  ai.wAgentCodeIn, 
                wAgentLevel = (SELECT TOP(1) wType FROM @vAgentLevelMap WHERE wMapValue = MIN(map.wMapValue))
        INTO #vAgentLevel
        FROM RollsMary.dbo.mAgentIdentity ai WITH(NOLOCK)
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
            FROM RollsMary_Doc.dbo.eDocument ed WITH(NOLOCK)
            INNER JOIN (SELECT wAgentCodeIn FROM #vResult GROUP BY wAgentCodeIn) r ON r.wAgentCodeIn = ed.wRefRID AND ed.wRefTable = 'mAgent'
            WHERE wStatus = 'A' AND wCategory = 'AGENT' AND wType = 'PHOTO' AND ed.wSizeType = 'S'
        ) AS d WHERE d.RowNum = 1;

        UPDATE r
        SET r.wAgentPortrait = ed.wFileData
        FROM #vResult r
        INNER JOIN #vDocument vd ON vd.wAgentCodeIn = r.wAgentCodeIn
        INNER JOIN RollsMary_Doc.dbo.eDocument ed WITH(NOLOCK) ON ed.RowID = vd.RowID;
        -------------------------------戶口頭像--------------------------------

        SELECT wReqBookingRid,
               wReqBookingGUID,
               wReqBookingHotelRid,
               wReqBookingHotelGUID,
               wBookingType,
               wBookingTypeName,
               wAgentCodeIn,
               wAgentCode_Display,
               wAgentCName,
               wAgentEName,
               wAgentNickName,
               wAgentIdentity,
               wAgentIdentityColor,
               wAgentLevel,
               wAgentPortrait,
               wReqUserName,
               wReqUsrTel,
               wReqUsrTelExt,
               wReqUsrTelCountryCd,
               wReqDeptName,
               wFollowUserName,
               wDetail,
               wRemark,
               wReqStatus,
               wReqStatusName,
               wReqStatusColor,
               wCrtDt,
               wUpdDt,
               wRecordCount 
        FROM #vResult
        ORDER BY RowNum;

        IF OBJECT_ID('tempdb..#vAgentIdentity') IS NOT NULL
            DROP TABLE #vAgentIdentity;

        IF OBJECT_ID('tempdb..#vAgentLevel') IS NOT NULL
            DROP TABLE #vAgentLevel;

        IF OBJECT_ID('tempdb..#vDocument') IS NOT NULL
            DROP TABLE #vDocument;

        IF OBJECT_ID('tempdb..#vDeptReqRoomSummary') IS NOT NULL
            DROP TABLE #vDeptReqRoomSummary;

        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;
    END