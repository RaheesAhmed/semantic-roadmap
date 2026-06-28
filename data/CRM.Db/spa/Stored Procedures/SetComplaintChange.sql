CREATE PROC [spa].[SetComplaintChange]
    @pComplaintXML  XML,
    @pSendSunPeople CHAR(1) = 'Y',
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vComplaint TABLE ( RowID BIGINT PRIMARY KEY );
        
        IF @pComplaintXML IS NOT NULL
        BEGIN
            INSERT INTO @vComplaint (RowID)
            SELECT DISTINCT tmp.RowID FROM (
                SELECT RowID = T.tmp.value('@RowID', 'BIGINT')
                FROM @pComplaintXML.nodes('/DataSet/Record') T(tmp)
            ) tmp WHERE tmp.RowID > 0;
        END

        DECLARE @vComplaintActionLog_DataSet TABLE (
            RowID                   BIGINT,
            wComplaintRid           BIGINT,
            wTranDt                 DATETIME2(7),
            wRefNo                  VARCHAR(30),
            wAgentCodeIn            VARCHAR(14),
            wComplainantName        NVARCHAR(50),
            wPersonRid              BIGINT,
            wComplainantNickname    NVARCHAR(50),
            wComplainantTitle       NVARCHAR(30),
            wComplainantTel         VARCHAR(100),
            wType                   VARCHAR(30),
            wChannel                VARCHAR(30),
            wReceivedBy             BIGINT,
            wReceivedDeptCd         VARCHAR(30),
            wReceivedLocation       NVARCHAR(30),
            wComplainBy             BIGINT,
            wComplainDeptCd         VARCHAR(30),
            wComplainLocation       NVARCHAR(30),
            wComplainCompNo         INT,
            wContent                NVARCHAR(2000),
            wCancelRemark           NVARCHAR(500),
            wIntroduction           NVARCHAR(2000),
            wDealDt                 DATETIME2(7),
            wComplaintStatus        VARCHAR(30),
            wStatus                 CHAR(1),
            wCrtDt                  DATETIME2(7),
            wCrtBy                  BIGINT,
            wUpdDt                  DATETIME2(7),
            wUpdBy                  BIGINT,
            RecordState             CHAR(1) -- I/U/D
        );

        DECLARE @vComplaint_DataSet TABLE (
            RowID                   BIGINT NOT NULL,
            wTranDt                 DATETIME2(7) NOT NULL,
            wRefNo                  VARCHAR(30) NOT NULL,
            wAgentCodeIn            VARCHAR(14) NOT NULL,
            wComplainantName        NVARCHAR(50) NOT NULL,
            wPersonRid              BIGINT NOT NULL,
            wComplainantNickname    NVARCHAR(50) NOT NULL,
            wComplainantTitle       NVARCHAR(30) NOT NULL,
            wComplainantTel         VARCHAR(100) NOT NULL,
            wType                   VARCHAR(30) NOT NULL,
            wChannel                VARCHAR(30) NOT NULL,
            wReceivedBy             BIGINT NOT NULL,
            wReceivedDeptCd         VARCHAR(30) NOT NULL,
            wReceivedLocation       NVARCHAR(30) NOT NULL,
            wComplainBy             BIGINT NOT NULL,
            wComplainDeptCd         VARCHAR(30) NOT NULL,
            wComplainLocation       NVARCHAR(30) NOT NULL,
            wComplainCompNo         INT NOT NULL,
            wContent                NVARCHAR(2000) NOT NULL,
            wCancelRemark           NVARCHAR(500) NOT NULL,
            wIntroduction           NVARCHAR(2000) NOT NULL,
            wDealDt                 DATETIME2(7) NOT NULL,
            wComplaintStatus        VARCHAR(30) NOT NULL,
            wStatus                 CHAR(1) NOT NULL,
            wCrtDt                  DATETIME2(7) NOT NULL,
            wCrtBy                  BIGINT NOT NULL,
            wUpdDt                  DATETIME2(7) NOT NULL,
            wUpdBy                  BIGINT NOT NULL,
            wComplaintActionLogRid  BIGINT NOT NULL
        );

        -- 最新記錄內容
        INSERT INTO @vComplaint_DataSet
        SELECT  c.RowID,
                c.wTranDt,
                c.wRefNo,
                c.wAgentCodeIn,
                c.wComplainantName,
                c.wPersonRid,
                c.wComplainantNickname,
                c.wComplainantTitle,
                c.wComplainantTel,
                c.wType,
                c.wChannel,
                c.wReceivedBy,
                c.wReceivedDeptCd,
                c.wReceivedLocation,
                c.wComplainBy,
                c.wComplainDeptCd,
                c.wComplainLocation,
                c.wComplainCompNo,
                c.wContent,
                c.wCancelRemark,
                c.wIntroduction,
                c.wDealDt,
                c.wComplaintStatus,
                c.wStatus,
                c.wCrtDt,
                c.wCrtBy,
                c.wUpdDt,
                c.wUpdBy,
                wComplaintActionLogRid = 0
        FROM dbo.eComplaint c
        INNER JOIN @vComplaint tmp ON tmp.RowID = c.RowID;

        -- 上一次修改記錄內容
        INSERT INTO @vComplaint_DataSet
        SELECT  c_log.wComplaintRid,
                c_log.wTranDt,
                c_log.wRefNo,
                c_log.wAgentCodeIn,
                c_log.wComplainantName,
                c_log.wPersonRid,
                c_log.wComplainantNickname,
                c_log.wComplainantTitle,
                c_log.wComplainantTel,
                c_log.wType,
                c_log.wChannel,
                c_log.wReceivedBy,
                c_log.wReceivedDeptCd,
                c_log.wReceivedLocation,
                c_log.wComplainBy,
                c_log.wComplainDeptCd,
                c_log.wComplainLocation,
                c_log.wComplainCompNo,
                c_log.wContent,
                c_log.wCancelRemark,
                c_log.wIntroduction,
                c_log.wDealDt,
                c_log.wComplaintStatus,
                c_log.wStatus,
                c_log.wCrtDt,
                c_log.wCrtBy,
                c_log.wUpdDt,
                c_log.wUpdBy,
                wComplaintActionLogRid = c_log.RowID
        FROM ( SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY c_log.wComplaintRid ORDER BY c_log.wUpdDt DESC),
                      c_log.* 
               FROM dbo.eComplaintActionLog c_log
               INNER JOIN @vComplaint tmp ON tmp.RowID = c_log.wComplaintRid
        ) c_log WHERE c_log.RowNum = 1;

        -- 當任意數據發生變化（不包括wCrtDt, wCrtBy, wUpdDt, wUpdBy），Insert一條新的記錄到ActionLog
        INSERT INTO @vComplaintActionLog_DataSet
        SELECT  RowID                   = 0,
                wComplaintRid           = new.RowID,
                wTranDt                 = new.wTranDt,
                wRefNo                  = new.wRefNo,
                wAgentCodeIn            = new.wAgentCodeIn,
                wComplainantName        = new.wComplainantName,
                wPersonRid              = new.wPersonRid,
                wComplainantNickname    = new.wComplainantNickname,
                wComplainantTitle       = new.wComplainantTitle,
                wComplainantTel         = new.wComplainantTel,
                wType                   = new.wType,
                wChannel                = new.wChannel,
                wReceivedBy             = new.wReceivedBy,
                wReceivedDeptCd         = new.wReceivedDeptCd,
                wReceivedLocation       = new.wReceivedLocation,
                wComplainBy             = new.wComplainBy,
                wComplainDeptCd         = new.wComplainDeptCd,
                wComplainLocation       = new.wComplainLocation,
                wComplainCompNo         = new.wComplainCompNo,
                wContent                = new.wContent,
                wCancelRemark           = new.wCancelRemark,
                wIntroduction           = new.wIntroduction,
                wDealDt                 = new.wDealDt,
                wComplaintStatus        = new.wComplaintStatus,
                wStatus                 = new.wStatus,
                wCrtDt                  = new.wCrtDt,
                wCrtBy                  = new.wCrtBy,
                wUpdDt                  = new.wUpdDt,
                wUpdBy                  = new.wUpdBy,
                RecordState             = 'I'
        FROM (SELECT * FROM @vComplaint_DataSet WHERE wComplaintActionLogRid = 0) new
        LEFT JOIN (SELECT * FROM @vComplaint_DataSet WHERE wComplaintActionLogRid <> 0) old ON old.RowID = new.RowID
        WHERE old.RowID IS NULL
           OR old.wTranDt                 <> new.wTranDt
           OR old.wRefNo                  <> new.wRefNo
           OR old.wAgentCodeIn            <> new.wAgentCodeIn
           OR old.wComplainantName        <> new.wComplainantName
           OR old.wPersonRid              <> new.wPersonRid
           OR old.wComplainantNickname    <> new.wComplainantNickname
           OR old.wComplainantTitle       <> new.wComplainantTitle
           OR old.wComplainantTel         <> new.wComplainantTel
           OR old.wType                   <> new.wType
           OR old.wChannel                <> new.wChannel
           OR old.wReceivedBy             <> new.wReceivedBy
           OR old.wReceivedDeptCd         <> new.wReceivedDeptCd
           OR old.wReceivedLocation       <> new.wReceivedLocation
           OR old.wComplainBy             <> new.wComplainBy
           OR old.wComplainDeptCd         <> new.wComplainDeptCd
           OR old.wComplainLocation       <> new.wComplainLocation
           OR old.wComplainCompNo         <> new.wComplainCompNo
           OR old.wContent                <> new.wContent
           OR old.wCancelRemark           <> new.wCancelRemark
           OR old.wIntroduction           <> new.wIntroduction
           OR old.wDealDt                 <> new.wDealDt
           OR old.wComplaintStatus        <> new.wComplaintStatus
           OR old.wStatus                 <> new.wStatus;

        -- Update
        INSERT INTO @vComplaintActionLog_DataSet
        SELECT  RowID                   = old.wComplaintActionLogRid,
                wComplaintRid           = new.RowID,
                wTranDt                 = new.wTranDt,
                wRefNo                  = new.wRefNo,
                wAgentCodeIn            = new.wAgentCodeIn,
                wComplainantName        = new.wComplainantName,
                wPersonRid              = new.wPersonRid,
                wComplainantNickname    = new.wComplainantNickname,
                wComplainantTitle       = new.wComplainantTitle,
                wComplainantTel         = new.wComplainantTel,
                wType                   = new.wType,
                wChannel                = new.wChannel,
                wReceivedBy             = new.wReceivedBy,
                wReceivedDeptCd         = new.wReceivedDeptCd,
                wReceivedLocation       = new.wReceivedLocation,
                wComplainBy             = new.wComplainBy,
                wComplainDeptCd         = new.wComplainDeptCd,
                wComplainLocation       = new.wComplainLocation,
                wComplainCompNo         = new.wComplainCompNo,
                wContent                = new.wContent,
                wCancelRemark           = new.wCancelRemark,
                wIntroduction           = new.wIntroduction,
                wDealDt                 = new.wDealDt,
                wComplaintStatus        = new.wComplaintStatus,
                wStatus                 = new.wStatus,
                wCrtDt                  = new.wCrtDt,
                wCrtBy                  = new.wCrtBy,
                wUpdDt                  = new.wUpdDt,
                wUpdBy                  = new.wUpdBy,
                RecordState             = 'U'
        FROM (SELECT * FROM @vComplaint_DataSet WHERE wComplaintActionLogRid = 0) new
        INNER JOIN (SELECT * FROM @vComplaint_DataSet WHERE wComplaintActionLogRid <> 0) old ON old.RowID = new.RowID
        WHERE old.wTranDt                 = new.wTranDt
          AND old.wRefNo                  = new.wRefNo
          AND old.wAgentCodeIn            = new.wAgentCodeIn
          AND old.wComplainantName        = new.wComplainantName
          AND old.wPersonRid              = new.wPersonRid
          AND old.wComplainantNickname    = new.wComplainantNickname
          AND old.wComplainantTitle       = new.wComplainantTitle
          AND old.wComplainantTel         = new.wComplainantTel
          AND old.wType                   = new.wType
          AND old.wChannel                = new.wChannel
          AND old.wReceivedBy             = new.wReceivedBy
          AND old.wReceivedDeptCd         = new.wReceivedDeptCd
          AND old.wReceivedLocation       = new.wReceivedLocation
          AND old.wComplainBy             = new.wComplainBy
          AND old.wComplainDeptCd         = new.wComplainDeptCd
          AND old.wComplainLocation       = new.wComplainLocation
          AND old.wComplainCompNo         = new.wComplainCompNo
          AND old.wContent                = new.wContent
          AND old.wCancelRemark           = new.wCancelRemark
          AND old.wIntroduction           = new.wIntroduction
          AND old.wDealDt                 = new.wDealDt
          AND old.wComplaintStatus        = new.wComplaintStatus
          AND old.wStatus                 = new.wStatus;
          
        DECLARE @vXML XML;

        -- Write Action Log
        -----------------------------------------------------------------------------------------
        SET @vXML = ( SELECT * FROM @vComplaintActionLog_DataSet FOR XML RAW('Record'), ROOT('DataSet'));

        EXEC spa.SetComplaintActionLog @pXML            = @vXML,
                                       @pReturnResult   = 'N',
                                       @pErrCode        = @pErrCode OUTPUT,
                                       @pErrMsg         = @pErrMsg OUTPUT;
        -----------------------------------------------------------------------------------------

        -- Set API Log 通知【SunPeople】
        -----------------------------------------------------------------------------------------
        IF @pSendSunPeople = 'Y'
        BEGIN
            SET @vXML = ( SELECT RowID = wComplaintRid FROM @vComplaintActionLog_DataSet WHERE RecordState = 'I' FOR XML RAW('Record'), ROOT('DataSet'));

            EXEC spa.SetComplaintRequestAssistantMonitorSummary @pTableName = 'eComplaint',
                                                                @pTableXML  = @vXML;
        END
        -----------------------------------------------------------------------------------------
    END