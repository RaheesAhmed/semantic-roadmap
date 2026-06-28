CREATE PROC [test].[GetRptBirthdayRefund]
    @pXMLBirthday XML,
    @pXMLFilter XML,
    @pLangCd VARCHAR(10) = 'zh-TW'
AS
    BEGIN
        DECLARE @pCalendarType   CHAR(5),
                @pRegion         VARCHAR(30),
                @pYear           INT,
                @pMonth          INT,
                @pBirthday       DATE,
                @sNow            DATETIME2(7) = GETDATE();

        DECLARE @vBirthday TABLE(
            wCalendarType   CHAR(5),
            wYear           INT,
            wMonth          INT,
            wDay            INT,
            wIsLeapMonth    CHAR(1),
            PRIMARY KEY(wCalendarType, wYear, wMonth, wDay, wIsLeapMonth)
        );

        DECLARE @tmpBirthday TABLE (
            wBirthdayRid BIGINT PRIMARY KEY
        );

        IF @pXMLFilter IS NOT NULL
        BEGIN
            SET @pCalendarType  = @pXMLFilter.value('(Filter/@pCalendarType)[1]',   'CHAR(5)');
            SET @pRegion        = @pXMLFilter.value('(Filter/@pRegion)[1]',         'VARCHAR(30)');
            SET @pYear          = @pXMLFilter.value('(Filter/@pYear)[1]',           'INT');
            SET @pMonth         = @pXMLFilter.value('(Filter/@pMonth)[1]',          'INT');

            SET @pCalendarType = NULLIF(@pCalendarType, '');
            SET @pRegion = NULLIF(@pRegion, '');
            SET @pBirthday = DATEFROMPARTS(@pYear, @pMonth, 1);
        END;

        IF @pXMLBirthday IS NOT NULL
        BEGIN
            INSERT INTO @vBirthday
            SELECT DISTINCT
                wCalendarType   = T.tmp.value('@pCalendarType',    'CHAR(5)'),
                wYear           = T.tmp.value('@pYear',             'INT'),
                wMonth          = T.tmp.value('@pMonth',            'INT'),
                wDay            = T.tmp.value('@pDay',              'INT'),
                wIsLeapMonth    = T.tmp.value('@pIsLeapMonth',      'CHAR(1)')    
            FROM @pXMLBirthday.nodes('DataSet/Record') T(tmp)
        END;

        -- 删除無效生日
        DELETE FROM @vBirthday WHERE wCalendarType NOT IN ('Solar', 'Lunar') OR wIsLeapMonth NOT IN ('Y', 'N');
        -- 篩選新舊曆
        IF @pCalendarType IS NOT NULL AND @pCalendarType IN ('Solar', 'Lunar')
        BEGIN
            DELETE FROM @vBirthday WHERE wCalendarType <> @pCalendarType;
        END;

        INSERT INTO @tmpBirthday( wBirthdayRid )
        SELECT DISTINCT
            eb.RowID
        FROM dbo.mVIPPerson mp
        INNER JOIN dbo.eBirthday eb ON eb.wVIPPersonRid = mp.RowID
        INNER JOIN @vBirthday vb ON 1 = 1
        WHERE vb.wCalendarType = mp.wCalendarType 
            AND vb.wYear = eb.wYear 
            AND vb.wMonth = mp.wMonth 
            AND vb.wDay = mp.wDay 
            AND vb.wIsLeapMonth = eb.wIsLeapMonth
            AND eb.wIsRefusedContact = 'N'
            AND eb.wStatus = 'A'
            AND (@pRegion IS NULL OR @pRegion = eb.wRegion);

        ------------------------------------戶口身份------------------------------------------
        DECLARE @sAgentIdentityLookup TABLE(
            wAgentIdentity VARCHAR(20),
            wAgentIdentityName NVARCHAR(50)
        );

        INSERT INTO @sAgentIdentityLookup(wAgentIdentity, wAgentIdentityName)
        VALUES ('SHARE',                N'股東'    ),
               ('SEC_SHARE',            N'股東'),
               ('AGENT',                N'代理'    ),
               ('CREDIT_AGENT',         N'代理'),
               ('GAMBLERS',             N'玩家'    ),
               ('CREDIT_GAMBLERS',      N'玩家'),
               ('SEC_AGENT',            N'代理'),
               ('SEC_CREDIT_AGENT',     N'代理'),
               ('SEC_GAMBLERS',         N'玩家'),
               ('SEC_CREDIT_GAMBLERS',  N'玩家');
        -----------------------------------END 戶口身份----------------------------------------

	    ------------------------------------戶口級別--------------------------------------------
	    DECLARE @vAccountType AS TABLE (
	    	wCode VARCHAR(10) PRIMARY KEY,
	    	wTitle NVARCHAR(10)
	    );
	    INSERT INTO  @vAccountType(wCode, wTitle)
	    SELECT wCode, wTitle FROM dbo.fnGetAgentAccountType('zh-TW');
	    ------------------------------------END 戶口級別--------------------------------------------

        ------------------------------------客人身份-----------------------------------------------
        DECLARE @sPersonIdentityLookup TABLE(
            wPersonIdentity VARCHAR(20),
            wPersonIdentityName NVARCHAR(50)
        );

        INSERT INTO @sPersonIdentityLookup(wPersonIdentity, wPersonIdentityName)
        VALUES ('AUTH',                N'授權人'    ),
               ('BOSS',                N'幕後老闆'),
               ('CLIENT',              N'客人'    ),
               ('FAMILY',              N'家人'),
               ('OWNER',               N'戶主'    ),
               ('PARTNER',             N'拍檔'),
               ('STAFF',               N'伙計'),
               ('WARRANTOR',           N'借貸担保人'),
               ('ASSISTANT',           N'業務發展部助理'),
               ('MARKETNG',            N'市場部'),
               ('DIRECTOR',            N'總監');
        -----------------------------------END 客人身份---------------------------------------------  
            
        ---- 三月平均轉碼數
        DECLARE @sXMLAgentCodeIn XML;
        DECLARE @vRollingAvg TABLE(
            wAgentCodeIn VARCHAR(14) PRIMARY KEY, 
            wRollingAvgAmt NUMERIC(18, 4)
        );
         SET @sXMLAgentCodeIn = (
            SELECT wAgentCodeIn 
            FROM @tmpBirthday tmp
            INNER JOIN dbo.eBirthday eb ON eb.RowID = tmp.wBirthdayRid
            INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
            FOR XML RAW('Record'), ROOT('DataSet')
        );
        
        INSERT INTO @vRollingAvg EXEC spq.GetRollingAvgForBirthday @sXMLAgentCodeIn, @pBirthday;

        WITH  tResult AS
        (
        SELECT 
            ma.wAgentCode_Display ,                             --戶口號碼
            mp.wPersonName ,                                    --姓名
            mp.wPersonIdentity ,                                --客戶身份ID
            mp.wIsAuthorizer ,                                  --要根據此值來判斷客戶身份
            wAgentIdentityName = ai.wTitle ,                    --身份類別
            mp.wYear ,                                          --年
            mp.wMonth ,                                         --月
            mp.wDay,                                            --日
            mp.wGender,                                         --性別
            wSource = sl.wTitle,                                --生日日期資訊來源
            wRollingAvgAmt = ISNULL(rol.wRollingAvgAmt, 0) ,    --3個月平均轉碼
            eb.wCreditAmt ,                                     --欠M
            wBudgetAmt = ISNULL(bg.wBudgetAmt,0) ,              --BUDGET
            wGiftDescription ,                                  --計劃選購之禮物
            wCostAmt = ISNULL(bg.wCostAmt,0) ,                  --禮物價值
            wRate = mp.wBudgetRatio ,                           --比率
            mp.wCalendarType ,                                  --新曆(Solar)/舊曆(Lunar)
            eb.wGiftStatus,
            mp.wAgentCodeIn,
            wAgentIdentity = (SELECT wAgentIdentity FROM RollsMary.dbo.fnGetAgentIdentity(mp.wAgentCodeIn)),
            mp.wIsLeapMonth ,                                   --是否閏月
            wPersonIdentityName = CAST('' AS NVARCHAR(50)),      --客人身份
            wCostCurrency = ISNULL(wCostCurrency,''),
            wBudgetCurrency = ISNULL(wBudgetCurrency,'')
        FROM @tmpBirthday tmp
        INNER JOIN dbo.eBirthday eb ON eb.RowID = tmp.wBirthdayRid
        INNER JOIN dbo.mVIPPerson mp ON mp.RowID = eb.wVIPPersonRid
        INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAgentCodeIn
        LEFT JOIN dbo.eBirthdayGift bg ON bg.wBirthdayRid = eb.RowID
        LEFT JOIN @vAccountType ai ON ai.wCode = ma.wAccountType
        LEFT JOIN CRM.dbo.mLookUp sl ON sl.wCode = bg.wSource AND sl.wLangCd = @pLangCd AND sl.wType='VIP_BIRTHDAY_SOURCE'
        LEFT JOIN @vRollingAvg rol ON rol.wAgentCodeIn = mp.wAgentCodeIn
        WHERE bg.wBudgetAmt !=bg.wCostAmt
        )
        ----dbml
        --SELECT * FROM tResult;

        SELECT tResult.*
        INTO #vResult
        FROM tResult

        --更新戶口身份
        UPDATE vr
        SET vr.wAgentIdentityName = CASE WHEN ail.wAgentIdentityName IS NULL THEN ISNULL(vr.wAgentIdentityName,'')
                                         WHEN vr.wAgentIdentityName IS NULL THEN ail.wAgentIdentityName
                                         ELSE CONCAT(ail.wAgentIdentityName,'/',vr.wAgentIdentityName) END
        FROM  #vResult vr
        LEFT JOIN  @sAgentIdentityLookup ail  ON ail.wAgentIdentity = vr.wAgentIdentity

        UPDATE vr
        SET vr.wAgentIdentityName = CONCAT(N'星級','/',vr.wAgentIdentityName)
        FROM  #vResult vr
        INNER JOIN RollsMary.dbo.mAgentIdentity mi ON mi.wAgentCodeIn = vr.wAgentCodeIn
        LEFT JOIN RollsMary.dbo.mDepartment as dept ON dept.RowID = mi.wDeptRid
        WHERE  mi.wType = 'STAR' AND dept.wCode = 'DEVELOP'

        -- 禮物未送出，獲取最新的欠M數
        IF EXISTS(SELECT 1 FROM #vResult WHERE wGiftStatus <> 'Y')
        BEGIN
            UPDATE r
            SET r.wCreditAmt = ISNULL(ac.wRealOutstanding_CAP_OD + ac.wRealOutstanding_MTH_OD + ac.wRealOutstanding_MASTER_OD + ac.wRealOutstanding_CREDIT_OD + ac.wRealOutstanding_IOU_OD + ac.wRealOutstanding_CIO_OD + ac.wOutstanding_CH_OD + ac.wRealOutstanding_F_OD + ac.wRealOutstanding_Y_OD, 0)
            FROM #vResult r
            LEFT JOIN RollsMary.dbo.mAgentCredit ac ON ac.wAgentCodeIn = r.wAgentCodeIn
            WHERE ac.wType = 'LIVE' AND r.wGiftStatus <> 'Y'
        END;
        
        --更新客人身份
        UPDATE vr
        SET vr.wPersonIdentityName = ml.wTitle
        FROM  #vResult vr
        INNER JOIN  dbo.mlookup ml  ON vr.wPersonIdentity = ml.wCode AND ml.wType='VIP_PERSON_IDENTITY' AND ml.wLangCd=@pLangCd
        WHERE vr.wIsAuthorizer !='Y'

        UPDATE vr
        SET vr.wPersonIdentityName = al.wPersonIdentityName
        FROM  #vResult vr
        INNER JOIN  @sPersonIdentityLookup al  ON vr.wPersonIdentity = al.wPersonIdentity 
        WHERE vr.wIsAuthorizer ='Y'

        --更新客人姓名
        UPDATE vr
        SET vr.wPersonName = CASE WHEN ISNULL(vr.wPersonIdentityName,'')='' THEN vr.wPersonName
                                  ELSE CONCAT(vr.wPersonIdentityName,':',vr.wPersonName) END
        FROM  #vResult vr

        SELECT * FROM #vResult 
        ORDER BY wRollingAvgAmt DESC;
        
        IF OBJECT_ID('tempdb..#vResult') IS NOT NULL
            DROP TABLE #vResult;

    END;