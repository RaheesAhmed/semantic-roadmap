CREATE PROC [spa].[SetDeptRespRoomChange]
    @pDeptRespRoomXML   XML,
    @pMainCompNo        INT,
    @pReturnResult      CHAR(1) = 'N',
    @pErrCode           INT OUTPUT,
    @pErrMsg            NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vDeptRespRoom TABLE ( RowID BIGINT PRIMARY KEY );
        
        IF @pDeptRespRoomXML IS NOT NULL
        BEGIN
            INSERT INTO @vDeptRespRoom (RowID)
            SELECT DISTINCT tmp.RowID FROM (
                SELECT RowID = T.tmp.value('@RowID', 'BIGINT')
                FROM @pDeptRespRoomXML.nodes('/DataSet/Record') T(tmp)
            ) tmp WHERE tmp.RowID > 0;
        END
        
        DECLARE @vDeptRespRoomActionLog_DataSet TABLE (
            RowID               BIGINT,
            wDeptReqRoomRid     BIGINT,
            wDeptRespRoomRid    BIGINT,
            wBookingRid         BIGINT,
            wGUID               UNIQUEIDENTIFIER,
            wHotelRid           BIGINT,
            wRoomRid            BIGINT,
            wBigBedQty          INT,
            wTwinBedQty         INT,
            wSuiteRoom1Qty      INT,
            wSuiteRoom2Qty      INT,
            wSuiteRoom3Qty      INT,
            wDayOfStay          INT,
            wStartDate          DATE,
            wEndDate            DATE,
            wIsApproved         CHAR(1),
            wTotalAmount        NUMERIC(18, 4),
            wRemark             NVARCHAR(4000),
            wCancelReason       NVARCHAR(500),
            wStatus             VARCHAR(20),
            wDeptStatus         VARCHAR(20),
            wRepStatus          VARCHAR(20),
            wIsExtRoom          CHAR(1),
            wCrtDt              DATETIME2(7),
            wCrtBy              BIGINT,
            wUpdDt              DATETIME2(7),
            wUpdBy              BIGINT,
            RecordState         CHAR(1) -- I/U/D
        );

        DECLARE @vDeptRespRoom_DataSet TABLE (
            RowID               BIGINT NOT NULL,
            wHotelRid           BIGINT NOT NULL,
            wRoomRid            BIGINT NOT NULL,
            wBigBedQty          INT NOT NULL,
            wTwinBedQty         INT NOT NULL,
            wSuiteRoom1Qty      INT NOT NULL,
            wDayOfStay          INT NOT NULL,
            wStartDate          DATE NOT NULL,
            wEndDate            DATE NOT NULL,
            wStatus             VARCHAR(20) NOT NULL,
            wRepStatus          VARCHAR(20) NOT NULL,
            wRemark             NVARCHAR(4000) NULL,
            wCrtDt              DATETIME2(7) NOT NULL,
            wCrtBy              BIGINT NOT NULL,
            wUpdDt              DATETIME2(7) NOT NULL,
            wUpdBy              BIGINT NOT NULL,
            wDeptReqRoomRid     BIGINT NOT NULL,
            wIsApproved         CHAR(1) NOT NULL,
            wTotalAmount        NUMERIC(18, 4) NOT NULL,
            wDeptStatus         VARCHAR(20) NOT NULL,
            wBookingRid         BIGINT NOT NULL,
            wCancelReason       NVARCHAR(500) NOT NULL,
            wSuiteRoom2Qty      INT NOT NULL,
            wSuiteRoom3Qty      INT NOT NULL,
            wGUID               UNIQUEIDENTIFIER NOT NULL,
            wIsExtRoom          CHAR(1) NOT NULL,
            wDeptRespRoomActionLogRid BIGINT NOT NULL
        );
        
        -- New
        INSERT INTO @vDeptRespRoom_DataSet
        SELECT resp.RowID,
               resp.wHotelRid,
               resp.wRoomRid,
               resp.wBigBedQty,
               resp.wTwinBedQty,
               resp.wSuiteRoom1Qty,
               resp.wDayOfStay,
               resp.wStartDate,
               resp.wEndDate,
               resp.wStatus,
               resp.wRepStatus,
               ISNULL(resp.wRemark, ''),
               resp.wCrtDt,
               resp.wCrtBy,
               resp.wUpdDt,
               resp.wUpdBy,
               resp.wDeptReqRoomRid,
               resp.wIsApproved,
               resp.wTotalAmount,
               resp.wDeptStatus,
               resp.wBookingRid,
               resp.wCancelReason,
               resp.wSuiteRoom2Qty,
               resp.wSuiteRoom3Qty,
               resp.wGUID,
               resp.wIsExtRoom,
               wDeptRespRoomActionLogRid = 0
        FROM dbo.eDeptRespRoom resp
        INNER JOIN @vDeptRespRoom tmp ON tmp.RowID = resp.RowID;
        
        -- latest
        INSERT INTO @vDeptRespRoom_DataSet
        SELECT resp_log.wDeptRespRoomRid,
               resp_log.wHotelRid,
               resp_log.wRoomRid,
               resp_log.wBigBedQty,
               resp_log.wTwinBedQty,
               resp_log.wSuiteRoom1Qty,
               resp_log.wDayOfStay,
               resp_log.wStartDate,
               resp_log.wEndDate,
               resp_log.wStatus,
               resp_log.wRepStatus,
               ISNULL(resp_log.wRemark, ''),
               resp_log.wCrtDt,
               resp_log.wCrtBy,
               resp_log.wUpdDt,
               resp_log.wUpdBy,
               resp_log.wDeptReqRoomRid,
               resp_log.wIsApproved,
               resp_log.wTotalAmount,
               resp_log.wDeptStatus,
               resp_log.wBookingRid,
               resp_log.wCancelReason,
               resp_log.wSuiteRoom2Qty,
               resp_log.wSuiteRoom3Qty,
               resp_log.wGUID,
               resp_log.wIsExtRoom,
               wDeptRespRoomActionLogRid = resp_log.RowID
        FROM ( SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY resp_log.wDeptRespRoomRid ORDER BY resp_log.wUpdDt DESC),
                      resp_log.* 
               FROM dbo.eDeptRespRoomActionLog resp_log
               INNER JOIN @vDeptRespRoom tmp ON tmp.RowID = resp_log.wDeptRespRoomRid
        ) resp_log WHERE resp_log.RowNum = 1;
        
        -- 當任意數據發生變化（不包括wGUID，wUpdDt），Insert一條新的記錄到ActionLog
        INSERT INTO @vDeptRespRoomActionLog_DataSet
        SELECT  RowID               = 0,
                wDeptReqRoomRid     = new.wDeptReqRoomRid,
                wDeptRespRoomRid    = new.RowID,
                wBookingRid         = new.wBookingRid,
                wGUID               = new.wGUID,
                wHotelRid           = new.wHotelRid,
                wRoomRid            = new.wRoomRid,
                wBigBedQty          = new.wBigBedQty,
                wTwinBedQty         = new.wTwinBedQty,
                wSuiteRoom1Qty      = new.wSuiteRoom1Qty,
                wSuiteRoom2Qty      = new.wSuiteRoom2Qty,
                wSuiteRoom3Qty      = new.wSuiteRoom3Qty,
                wDayOfStay          = new.wDayOfStay,
                wStartDate          = new.wStartDate,
                wEndDate            = new.wEndDate,
                wIsApproved         = new.wIsApproved,
                wTotalAmount        = new.wTotalAmount,
                wRemark             = new.wRemark,
                wCancelReason       = new.wCancelReason,
                wStatus             = new.wStatus,
                wDeptStatus         = new.wDeptStatus,
                wRepStatus          = new.wRepStatus,
                wIsExtRoom          = new.wIsExtRoom,
                wCrtDt              = new.wCrtDt,
                wCrtBy              = new.wCrtBy,
                wUpdDt              = new.wUpdDt,
                wUpdBy              = new.wUpdBy,
                RecordState         = 'I'
        FROM (SELECT * FROM @vDeptRespRoom_DataSet WHERE wDeptRespRoomActionLogRid = 0) new
        LEFT JOIN (SELECT * FROM @vDeptRespRoom_DataSet WHERE wDeptRespRoomActionLogRid <> 0) old ON old.RowID = new.RowID
        WHERE old.RowID IS NULL
           OR new.wHotelRid       <> old.wHotelRid
           OR new.wRoomRid        <> old.wRoomRid
           OR new.wBigBedQty      <> old.wBigBedQty
           OR new.wTwinBedQty     <> old.wTwinBedQty
           OR new.wSuiteRoom1Qty  <> old.wSuiteRoom1Qty
           OR new.wDayOfStay      <> old.wDayOfStay
           OR new.wStartDate      <> old.wStartDate
           OR new.wEndDate        <> old.wEndDate
           OR new.wStatus         <> old.wStatus
           OR new.wRepStatus      <> old.wRepStatus
           OR new.wRemark         <> old.wRemark
           OR new.wCrtDt          <> old.wCrtDt
           OR new.wCrtBy          <> old.wCrtBy
           OR new.wUpdBy          <> old.wUpdBy
           OR new.wDeptReqRoomRid <> old.wDeptReqRoomRid
           OR new.wIsApproved     <> old.wIsApproved
           OR new.wTotalAmount    <> old.wTotalAmount
           OR new.wDeptStatus     <> old.wDeptStatus
           OR new.wBookingRid     <> old.wBookingRid
           OR new.wCancelReason   <> old.wCancelReason
           OR new.wSuiteRoom2Qty  <> old.wSuiteRoom2Qty
           OR new.wSuiteRoom3Qty  <> old.wSuiteRoom3Qty
           OR new.wIsExtRoom      <> old.wIsExtRoom;
           
        -- update
        INSERT INTO @vDeptRespRoomActionLog_DataSet
        SELECT  RowID               = old.wDeptRespRoomActionLogRid,
                wDeptReqRoomRid     = new.wDeptReqRoomRid,
                wDeptRespRoomRid    = new.RowID,
                wBookingRid         = new.wBookingRid,
                wGUID               = new.wGUID,
                wHotelRid           = new.wHotelRid,
                wRoomRid            = new.wRoomRid,
                wBigBedQty          = new.wBigBedQty,
                wTwinBedQty         = new.wTwinBedQty,
                wSuiteRoom1Qty      = new.wSuiteRoom1Qty,
                wSuiteRoom2Qty      = new.wSuiteRoom2Qty,
                wSuiteRoom3Qty      = new.wSuiteRoom3Qty,
                wDayOfStay          = new.wDayOfStay,
                wStartDate          = new.wStartDate,
                wEndDate            = new.wEndDate,
                wIsApproved         = new.wIsApproved,
                wTotalAmount        = new.wTotalAmount,
                wRemark             = new.wRemark,
                wCancelReason       = new.wCancelReason,
                wStatus             = new.wStatus,
                wDeptStatus         = new.wDeptStatus,
                wRepStatus          = new.wRepStatus,
                wIsExtRoom          = new.wIsExtRoom,
                wCrtDt              = new.wCrtDt,
                wCrtBy              = new.wCrtBy,
                wUpdDt              = new.wUpdDt,
                wUpdBy              = new.wUpdBy,
                RecordState         = 'U'
        FROM (SELECT * FROM @vDeptRespRoom_DataSet WHERE wDeptRespRoomActionLogRid = 0) new
        LEFT JOIN (SELECT * FROM @vDeptRespRoom_DataSet WHERE wDeptRespRoomActionLogRid <> 0) old ON old.RowID = new.RowID
        WHERE new.wHotelRid       = old.wHotelRid
          AND new.wRoomRid        = old.wRoomRid
          AND new.wBigBedQty      = old.wBigBedQty
          AND new.wTwinBedQty     = old.wTwinBedQty
          AND new.wSuiteRoom1Qty  = old.wSuiteRoom1Qty
          AND new.wDayOfStay      = old.wDayOfStay
          AND new.wStartDate      = old.wStartDate
          AND new.wEndDate        = old.wEndDate
          AND new.wStatus         = old.wStatus
          AND new.wRepStatus      = old.wRepStatus
          AND new.wRemark         = old.wRemark
          AND new.wCrtDt          = old.wCrtDt
          AND new.wCrtBy          = old.wCrtBy
          AND new.wUpdBy          = old.wUpdBy
          AND new.wDeptReqRoomRid = old.wDeptReqRoomRid
          AND new.wIsApproved     = old.wIsApproved
          AND new.wTotalAmount    = old.wTotalAmount
          AND new.wDeptStatus     = old.wDeptStatus
          AND new.wBookingRid     = old.wBookingRid
          AND new.wCancelReason   = old.wCancelReason
          AND new.wSuiteRoom2Qty  = old.wSuiteRoom2Qty
          AND new.wSuiteRoom3Qty  = old.wSuiteRoom3Qty
          AND new.wIsExtRoom      = old.wIsExtRoom;
        
        DECLARE @vXML XML;

        SET @vXML = ( SELECT * FROM @vDeptRespRoomActionLog_DataSet FOR XML RAW('Record'), ROOT('DataSet'));
        
        EXEC spa.SetDeptRespRoomActionLog @pXML          = @vXML,
                                          @pMainCompNo   = @pMainCompNo,
                                          @pReturnResult = @pReturnResult,
                                          @pTestMode     = 0,
                                          @pErrCode      = @pErrCode OUTPUT,
                                          @pErrMsg       = @pErrMsg OUTPUT
    END