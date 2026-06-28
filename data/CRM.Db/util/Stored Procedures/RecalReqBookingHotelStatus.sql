CREATE PROC [util].[RecalReqBookingHotelStatus]
    @pXML           XML,
    @pMainCompNo    INT,
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vXML XML,
                @sNow DATETIME2(7) = dbo.fnUTC8Now();

        CREATE TABLE #vDeptReqRoom_DataSet (RowID BIGINT, wUpdBy BIGINT, wFollowDeptCd VARCHAR(30), wFollowUserRid BIGINT);

        INSERT INTO #vDeptReqRoom_DataSet (RowID, wUpdBy, wFollowDeptCd, wFollowUserRid)
        SELECT tmp.RowID, tmp.wUpdBy, tmp.wFollowDeptCd, tmp.wFollowUserRid FROM (
            SELECT RowID            = T.tmp.value('@wDeptReqRoomRid',  'BIGINT'),
                   wUpdBy           = T.tmp.value('@wUpdBy',          'BIGINT'),
                   wFollowDeptCd    = T.tmp.value('@wFollowDeptCd', 'VARCHAR(30)'),
                   wFollowUserRid   = T.tmp.value('@wFollowUserRid', 'BIGINT')
            FROM @pXML.nodes('DataSet/Record') T(tmp)
        ) tmp WHERE tmp.RowID > 0 AND tmp.wUpdBy > 0
        GROUP BY tmp.RowID, tmp.wUpdBy, tmp.wFollowDeptCd, tmp.wFollowUserRid;

        -- 需求狀態對照表
        ------------------------------------------------------------
        DECLARE @vStatusMap AS TABLE(
            wStatus VARCHAR(20),
            wMapValue INT,
            wStatusName NVARCHAR(50)
            PRIMARY KEY(wStatus, wMapValue)
        );
        INSERT INTO @vStatusMap( 
            wStatus, 
            wMapValue, 
            wStatusName 
        )
        SELECT  wStatus     = wCode, 
                wMapValue   = wSeqNo, 
                wStatusName = wTitle
        FROM dbo.mLookUp
        WHERE wType = 'DEPTROOM_RESPONSE_STATUS' AND wLangCd = 'zh-TW';
        ------------------------------------------------------------

        -- 完成狀態（計算得出）
        ;WITH cteReqStatus AS (
            SELECT RowID = rep.wDeptReqRoomRid,
                   wReqStatus = ( SELECT TOP(1) wStatus FROM @vStatusMap WHERE wMapValue = MIN(map.wMapValue))
            FROM dbo.eDeptRespRoom AS rep WITH(NOLOCK)
            INNER JOIN @vStatusMap AS map ON rep.wRepStatus = map.wStatus
            WHERE rep.wDeptReqRoomRid > 0 AND rep.wStatus = 'A'
            GROUP BY rep.wDeptReqRoomRid
        )

        SELECT rb.RowID,
               rb.wGUID,
               rb.wBookingType,
               rb.wRefTable,
               rb.wRefRid,
               rb.wRefNo,
               rb.wAgentCodeIn,
               rb.wReqDeptCd,
               rb.wReqUserRid,
               wFollowDeptCd = ISNULL(tmp.wFollowDeptCd, rb.wFollowDeptCd),
               wFollowUserRid = ISNULL(tmp.wFollowUserRid, rb.wFollowUserRid),
               wReqStatus = IIF(rs.wReqStatus IS NULL, rb.wReqStatus, IIF(rs.wReqStatus = 'NEW', 'P', rs.wReqStatus)),
               rb.wStatus,
               rb.wCrtBy,
               rb.wCrtDt,
               wUpdBy = tmp.wUpdBy,
               wUpdDt = @sNow,
               RecordState = 'U'
        INTO #vReqBooking_DataSet
        FROM dbo.eReqBooking rb WITH(NOLOCK)
        LEFT JOIN cteReqStatus rs ON rs.RowID = rb.wRefRid
        LEFT JOIN #vDeptReqRoom_DataSet tmp ON tmp.RowID = rb.wRefRid
        WHERE rb.wStatus = 'A'
            AND rb.wAgentCodeIn != ''
            AND rb.wBookingType = 'HOTEL'
            AND ( @pXML IS NULL OR ISNULL(tmp.RowID, 0) > 0 );
            
        SET @vXML = (SELECT * FROM #vReqBooking_DataSet FOR XML RAW('Record'), ROOT('DataSet'));
        
        IF OBJECT_ID('tempdb..#vReqBooking_DataSet') IS NOT NULL
            DROP TABLE #vReqBooking_DataSet;

        IF OBJECT_ID('tempdb..#vDeptReqRoom_DataSet') IS NOT NULL
            DROP TABLE #vDeptReqRoom_DataSet;

        EXEC spa.SetReqBooking @pXML = @vXML,
                               @pMainCompNo = @pMainCompNo,
                               @pReturnResult = 'N',
                               @pTestMode = 0,
                               @pErrCode = @pErrCode OUTPUT,
                               @pErrMsg = @pErrMsg OUTPUT;
    END