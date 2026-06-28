CREATE PROC [spa].[SetAdviceChange]
    @pAdviceXML     XML,
    @pSendSunPeople CHAR(1) = 'Y',
    @pErrCode       INT OUTPUT,
    @pErrMsg        NVARCHAR(200) OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @vAdvice TABLE ( RowID BIGINT PRIMARY KEY );
        
        IF @pAdviceXML IS NOT NULL
        BEGIN
            INSERT INTO @vAdvice (RowID)
            SELECT DISTINCT tmp.RowID FROM (
                SELECT RowID = T.tmp.value('@RowID', 'BIGINT')
                FROM @pAdviceXML.nodes('DataSet/Record') T(tmp)
            ) tmp WHERE tmp.RowID > 0;
        END

        DECLARE @vAdviceActionLog_DataSet TABLE (
            RowID               BIGINT,
            wAdviceRid          BIGINT,
            wAim                NVARCHAR(200),
            wDate               DATE,
            wAgentCodeIn        VARCHAR(14),
            wReceivedBy         BIGINT,
            wReceivedDeptCd     VARCHAR(30),
            wType               VARCHAR(30),
            wSubType            VARCHAR(30),
            wContent            NVARCHAR(2000),
            wIsHighPriority     CHAR(1),
            wRefNo              VARCHAR(30),
            wDealDt             DATETIME2(7),
            wAdviceStatus       VARCHAR(20),
            wStatus             CHAR(1),
            wCrtDt              DATETIME2(7),
            wCrtBy              BIGINT,
            wUpdDt              DATETIME2(7),
            wUpdBy              BIGINT,
            RecordState         CHAR(1) -- I/U/D
        );

        DECLARE @vAdvice_DataSet TABLE (
            RowID               BIGINT NOT NULL,
            wAim                NVARCHAR(200) NOT NULL,
            wDate               DATE NOT NULL,
            wAgentCodeIn        VARCHAR(14) NOT NULL,
            wReceivedBy         BIGINT NOT NULL,
            wReceivedDeptCd     VARCHAR(30) NOT NULL,
            wType               VARCHAR(30) NOT NULL,
            wSubType            VARCHAR(30) NOT NULL,
            wContent            NVARCHAR(2000) NOT NULL,
            wIsHighPriority     CHAR(1) NOT NULL,
            wRefNo              VARCHAR(30) NOT NULL,
            wDealDt             DATETIME2(7) NOT NULL,
            wAdviceStatus       VARCHAR(20) NOT NULL,
            wStatus             CHAR(1) NOT NULL,
            wCrtDt              DATETIME2(7) NOT NULL,
            wCrtBy              BIGINT NOT NULL,
            wUpdDt              DATETIME2(7) NOT NULL,
            wUpdBy              BIGINT NOT NULL,
            wAdviceActionLogRid BIGINT NOT NULL
        );

        -- 最新記錄內容
        INSERT INTO @vAdvice_DataSet
        SELECT  a.RowID,
                a.wAim,
                a.wDate,
                a.wAgentCodeIn,
                a.wReceivedBy,
                a.wReceivedDeptCd,
                a.wType,
                a.wSubType,
                a.wContent,
                a.wIsHighPriority,
                a.wRefNo,
                a.wDealDt,
                a.wAdviceStatus,
                a.wStatus,
                a.wCrtDt,
                a.wCrtBy,
                a.wUpdDt,
                a.wUpdBy,
                wAdviceActionLogRid = 0
        FROM dbo.eAdvice a
        INNER JOIN @vAdvice tmp ON tmp.RowID = a.RowID;

        -- 上一次修改記錄內容
        INSERT INTO @vAdvice_DataSet
        SELECT  a_log.wAdviceRid,
                a_log.wAim,
                a_log.wDate,
                a_log.wAgentCodeIn,
                a_log.wReceivedBy,
                a_log.wReceivedDeptCd,
                a_log.wType,
                a_log.wSubType,
                a_log.wContent,
                a_log.wIsHighPriority,
                a_log.wRefNo,
                a_log.wDealDt,
                a_log.wAdviceStatus,
                a_log.wStatus,
                a_log.wCrtDt,
                a_log.wCrtBy,
                a_log.wUpdDt,
                a_log.wUpdBy,
                wAdviceActionLogRid = a_log.RowID
        FROM ( SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY a_log.wAdviceRid ORDER BY a_log.wUpdDt DESC),
                      a_log.* 
               FROM dbo.eAdviceActionLog a_log
               INNER JOIN @vAdvice tmp ON tmp.RowID = a_log.wAdviceRid
        ) a_log WHERE a_log.RowNum = 1;

        -- 當任意數據發生變化（不包括wCrtDt, wCrtBy, wUpdDt, wUpdBy），Insert一條新的記錄到ActionLog
        INSERT INTO @vAdviceActionLog_DataSet
        SELECT  RowID           = 0,
                wAdviceRid      = new.RowID,
                wAim            = new.wAim,
                wDate           = new.wDate,
                wAgentCodeIn    = new.wAgentCodeIn,
                wReceivedBy     = new.wReceivedBy,
                wReceivedDeptCd = new.wReceivedDeptCd,
                wType           = new.wType,
                wSubType        = new.wSubType,
                wContent        = new.wContent,
                wIsHighPriority = new.wIsHighPriority,
                wRefNo          = new.wRefNo,
                wDealDt         = new.wDealDt,
                wAdviceStatus   = new.wAdviceStatus,
                wStatus         = new.wStatus,
                wCrtDt          = new.wCrtDt,
                wCrtBy          = new.wCrtBy,
                wUpdDt          = new.wUpdDt,
                wUpdBy          = new.wUpdBy,
                RecordState     = 'I'
        FROM (SELECT * FROM @vAdvice_DataSet WHERE wAdviceActionLogRid = 0) new
        LEFT JOIN (SELECT * FROM @vAdvice_DataSet WHERE wAdviceActionLogRid <> 0) old ON old.RowID = new.RowID
        WHERE old.RowID IS NULL
           OR old.wAim            <> new.wAim
           OR old.wDate           <> new.wDate
           OR old.wAgentCodeIn    <> new.wAgentCodeIn
           OR old.wReceivedBy     <> new.wReceivedBy
           OR old.wReceivedDeptCd <> new.wReceivedDeptCd
           OR old.wType           <> new.wType
           OR old.wSubType        <> new.wSubType
           OR old.wContent        <> new.wContent
           OR old.wIsHighPriority <> new.wIsHighPriority
           OR old.wRefNo          <> new.wRefNo
           OR old.wDealDt         <> new.wDealDt
           OR old.wAdviceStatus   <> new.wAdviceStatus
           OR old.wStatus         <> new.wStatus;

        -- Update
        INSERT INTO @vAdviceActionLog_DataSet
        SELECT  RowID           = old.wAdviceActionLogRid,
                wAdviceRid      = new.RowID,
                wAim            = new.wAim,
                wDate           = new.wDate,
                wAgentCodeIn    = new.wAgentCodeIn,
                wReceivedBy     = new.wReceivedBy,
                wReceivedDeptCd = new.wReceivedDeptCd,
                wType           = new.wType,
                wSubType        = new.wSubType,
                wContent        = new.wContent,
                wIsHighPriority = new.wIsHighPriority,
                wRefNo          = new.wRefNo,
                wDealDt         = new.wDealDt,
                wAdviceStatus   = new.wAdviceStatus,
                wStatus         = new.wStatus,
                wCrtDt          = new.wCrtDt,
                wCrtBy          = new.wCrtBy,
                wUpdDt          = new.wUpdDt,
                wUpdBy          = new.wUpdBy,
                RecordState     = 'U'
        FROM (SELECT * FROM @vAdvice_DataSet WHERE wAdviceActionLogRid = 0) new
        INNER JOIN (SELECT * FROM @vAdvice_DataSet WHERE wAdviceActionLogRid <> 0) old ON old.RowID = new.RowID
        WHERE old.wAim            = new.wAim
          AND old.wDate           = new.wDate
          AND old.wAgentCodeIn    = new.wAgentCodeIn
          AND old.wReceivedBy     = new.wReceivedBy
          AND old.wReceivedDeptCd = new.wReceivedDeptCd
          AND old.wType           = new.wType
          AND old.wSubType        = new.wSubType
          AND old.wContent        = new.wContent
          AND old.wIsHighPriority = new.wIsHighPriority
          AND old.wRefNo          = new.wRefNo
          AND old.wDealDt         = new.wDealDt
          AND old.wAdviceStatus   = new.wAdviceStatus
          AND old.wStatus         = new.wStatus;

        DECLARE @vXML XML;

        -- Write Action Log
        -----------------------------------------------------------------------------------------
        SET @vXML = ( SELECT * FROM @vAdviceActionLog_DataSet FOR XML RAW('Record'), ROOT('DataSet'));

        EXEC spa.SetAdviceActionLog @pXML           = @vXML,
                                    @pReturnResult  = 'N',
                                    @pErrCode       = @pErrCode OUTPUT,
                                    @pErrMsg        = @pErrMsg OUTPUT;
        -----------------------------------------------------------------------------------------

        -- Set API Log 通知【SunPeople】
        -----------------------------------------------------------------------------------------
        IF @pSendSunPeople = 'Y'
        BEGIN
            SET @vXML = ( SELECT RowID = wAdviceRid FROM @vAdviceActionLog_DataSet WHERE RecordState = 'I' FOR XML RAW('Record'), ROOT('DataSet'));

            EXEC spa.SetComplaintRequestAssistantMonitorSummary @pTableName = 'eAdvice',
                                                                @pTableXML  = @vXML;
        END
        -----------------------------------------------------------------------------------------
    END