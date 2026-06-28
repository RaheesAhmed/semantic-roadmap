CREATE PROC [util].[RecalDeptRoomStatus]
    @pXML   XML = NULL
AS
    BEGIN
        SET NOCOUNT ON;

        CREATE TABLE #vDeptReqRoom_DataSet (RowID BIGINT);

        IF @pXML IS NOT NULL
        BEGIN
            INSERT INTO #vDeptReqRoom_DataSet (RowID)
            SELECT tmp.RowID FROM (
                SELECT RowID = T.tmp.value('@wDeptReqRoomRid', 'BIGINT')
                FROM @pXML.nodes('DataSet/Record') T(tmp)
            ) tmp WHERE tmp.RowID > 0
            GROUP BY tmp.RowID;
        END

        -- 需求狀態對照表
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

        -- 完成狀態（計算得出）
        SELECT  RowID = rep.wDeptReqRoomRid,
                wReqStatus = ( SELECT TOP(1) wStatus FROM @vStatusMap WHERE wMapValue = MIN(map.wMapValue))
        INTO #cteReqStatus
        FROM dbo.eDeptRespRoom AS rep
        INNER JOIN @vStatusMap AS map ON rep.wRepStatus = map.wStatus
        LEFT JOIN #vDeptReqRoom_DataSet tmp ON tmp.RowID = rep.wDeptReqRoomRid
        WHERE rep.wStatus = 'A'
            AND rep.wDeptReqRoomRid > 0
            AND (@pXML IS NULL OR tmp.RowID IS NOT NULL)
        GROUP BY rep.wDeptReqRoomRid;

        SELECT  RowID = rep.wDeptReqRoomRid,
                wIsExtRoom = 'Y'
        INTO #cteExtRoom
        FROM dbo.eDeptRespRoom AS rep
        LEFT JOIN #vDeptReqRoom_DataSet tmp ON tmp.RowID = rep.wDeptReqRoomRid
        WHERE rep.wStatus = 'A'
            AND rep.wDeptReqRoomRid > 0 
            AND rep.wIsExtRoom = 'Y' 
            AND (@pXML IS NULL OR tmp.RowID IS NOT NULL)
        GROUP BY rep.wDeptReqRoomRid;

        UPDATE req
        SET wReqStatus = ISNULL(rs.wReqStatus, 'NEW'),
            wIsExtRoom = ISNULL(er.wIsExtRoom, 'N')
        FROM dbo.eDeptReqRoom req
        LEFT JOIN #cteReqStatus rs ON rs.RowID = req.RowID
        LEFT JOIN #cteExtRoom er ON er.RowID = req.RowID
        LEFT JOIN #vDeptReqRoom_DataSet tmp ON tmp.RowID = req.RowID
        WHERE @pXML IS NULL OR tmp.RowID IS NOT NULL;

        IF OBJECT_ID('tempdb..#cteReqStatus') IS NOT NULL
            DROP TABLE #cteReqStatus;

        IF OBJECT_ID('tempdb..#cteExtRoom') IS NOT NULL
            DROP TABLE #cteExtRoom;

        IF OBJECT_ID('tempdb..#vDeptReqRoom_DataSet') IS NOT NULL
            DROP TABLE #vDeptReqRoom_DataSet;
    END