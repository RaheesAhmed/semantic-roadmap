
-- 導入RollsMary.dbo.mAgent的wType='AUTH'到VIP客戶資料
-- @pAgentCodeIn  = NULL， @pAuthorizerAgentCodeIn  = NULL，Insert OR Update 所有授權人到dbo.mVIPPerosn
-- @pAgentCodeIn  = NULL， @pAuthorizerAgentCodeIn <> NULL，Insert OR Update 指定授權人到dbo.mVIPPerosn
-- @pAgentCodeIn <> NULL， @pAuthorizerAgentCodeIn  = NULL，Insert OR Update 指定戶口下所有授權人到dbo.mVIPPerosn
-- @pAgentCodeIn <> NULL， @pAuthorizerAgentCodeIn <> NULL，Insert OR Update 指定戶口下指定授權人到dbo.mVIPPerosn
CREATE PROC [util].[RecalVIPPersonForAuthorizer]
    @pAgentCodeIn           VARCHAR(14) = '', -- 戶口
    @pAuthorizerAgentCodeIn VARCHAR(14) = '', -- 授權人
    @pActionType            CHAR(1)     = 'I' -- I/U
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @sThisTableName     VARCHAR(50) = 'mVIPPerson',
                @sBeginTranCount    INT,
                @sUpdBy             BIGINT,
                @sRowIndex          BIGINT,
                @sRecCount          BIGINT,
                @sRowID             BIGINT,
                @sErrCode           INT,
                @sErrMsg            NVARCHAR(200),
                @sNow               DATETIME2(7) = GETDATE();

        -- VIP、MD部門RowID
        DECLARE @sVIPDeptRid BIGINT,
                @sMDDeptRid  BIGINT;
        -- VIP、MD跟進的戶口
        DECLARE @vAgentFollow TABLE(wAgentCodeIn VARCHAR(14), wFollowDept VARCHAR(5), PRIMARY KEY(wAgentCodeIn, wFollowDept));
        -- MD跟進戶口身份組別
        DECLARE @vAgentIdentity TABLE(wType NVARCHAR(30) PRIMARY KEY);
        INSERT INTO @vAgentIdentity(wType) VALUES ('STAR'), ('HIGHLY_VALUED');

        -- 批額戶口
        DECLARE @sInXML     XML,
                @sOutXML    XML;
        CREATE TABLE #vAgentCredit(wAgentCodeIn VARCHAR(14) PRIMARY KEY);

        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pAuthorizerAgentCodeIn = NULLIF(@pAuthorizerAgentCodeIn, '');
        SET @pActionType = ISNULL(NULLIF(@pActionType, ''), 'I');
        -- 導入的數據，默認經手人為「系統」
        SET @sUpdBy = ISNULL(( SELECT TOP(1) RowID FROM RollsMary.dbo.mUsr WHERE wUsrId = 'SYSTEM' AND wName = 'System'), 0);
        -- VIP部門RowID
        SET @sVIPDeptRid = (SELECT TOP(1) RowID FROM RollsMary.dbo.mDepartment WHERE NULLIF(wUserLineGrp, '') IS NULL AND wCode = 'HOUSEKEEPER');
        -- MD部門RowID
        SET @sMDDeptRid = (SELECT TOP(1) RowID FROM RollsMary.dbo.mDepartment WHERE NULLIF(wUserLineGrp, '') IS NULL AND wCode = 'DEVELOP');

        SET @sBeginTranCount = @@trancount;
        SET @sErrCode = 0;
        SET @sErrMsg = '';

        BEGIN TRY
            IF @sBeginTranCount = 0
            BEGIN
                BEGIN TRAN;
            END;

            -- 插入客戶資料
            IF @pActionType = 'I'
            BEGIN
                CREATE TABLE #vVIPPerson (
                    wRowNum                 BIGINT, -- 此處不能用自增id，因為後面會根據跟進部門T掉不是VIP、MD跟進的Record
                    RowID                   BIGINT,
                    wAgentCodeIn            VARCHAR(14),
                    wPersonName             NVARCHAR(50),
                    wPersonIdentity         VARCHAR(30),
                    wGender                 VARCHAR(5), 
                    wAuthorizerAgentCodeIn  VARCHAR(14),
                    wAuthorizerIdentity     VARCHAR(30),
                    wRelationship           VARCHAR(30),
                    wOtherRelationship      NVARCHAR(200),
                    wBirthDate              DATE,
                    wCalendarType           CHAR(5),
                    wYear                   INT,
                    wMonth                  INT,
                    wDay                    INT,
                    wIsLeapMonth            CHAR(1),
                    wContactWay             VARCHAR(30),
                    wTelNumber              NVARCHAR(150),
                    wWhatsappNumber         VARCHAR(100),
                    wWeChatNumber           NVARCHAR(100),
                    wWeChatName             NVARCHAR(100),
                    wBudgetRatio            NUMERIC(18,4),
                    wIsWeChatVerify         CHAR(1),
                    wIsPresentGift          CHAR(1),
                    wIsAuthorizer           CHAR(1),
                    wVIPPersonStatus        CHAR(1),
                    wStatusRemark           NVARCHAR(4000),
                    wSource                 VARCHAR(10),
                    wIsRefusedContact       CHAR(1),
                    wStatus                 CHAR(1),
                    wCrtBy                  BIGINT,
                    wCrtDt                  DATETIME2(7),
                    wUpdBy                  BIGINT,
                    wUpdDt                  DATETIME2(7)
                );

                INSERT INTO #vVIPPerson(
                    RowID, 
                    wAgentCodeIn,
                    wPersonName, 
                    wPersonIdentity, 
                    wGender, 
                    wAuthorizerAgentCodeIn, 
                    wAuthorizerIdentity, 
                    wRelationship, 
                    wOtherRelationship,
                    wBirthDate, 
                    wCalendarType, 
                    wYear, 
                    wMonth, 
                    wDay, 
                    wIsLeapMonth,
                    wContactWay, 
                    wTelNumber, 
                    wWhatsappNumber, 
                    wWeChatNumber, 
                    wWeChatName, 
                    wBudgetRatio, 
                    wIsWeChatVerify, 
                    wIsPresentGift,
                    wIsAuthorizer,
                    wVIPPersonStatus, 
                    wStatusRemark,
                    wSource,
                    wIsRefusedContact,
                    wStatus,
                    wCrtBy, 
                    wCrtDt, 
                    wUpdBy, 
                    wUpdDt
                )
                SELECT
                    RowID = 0, 
                    wAgentCodeIn = ma.wUpLvlAgentCodeIn,
                    wPersonName = ma.wCName, 
                    wPersonIdentity = IIF(ma.wAuthIdentity = 'OWNER' OR ma.wAuthIdentity = 'BOSS', CONCAT('VIP', '_', ma.wAuthIdentity), 'VIP_CLIENT'), -- OWNER --> VIP_OWNER(VIP戶主)、BOSS --> VIP_BOSS（VIP幕後老闆）、其他 --> VIP_CLIENT(VIP客戶)
                    wGender = ma.wSex, 
                    wAuthorizerAgentCodeIn = ma.wAgentCodeIn, 
                    wAuthorizerIdentity    = ma.wAuthIdentity, 
                    wRelationship      = '000', 
                    wOtherRelationship = NULL,
                    wBirthDate = ISNULL(ma.wBirthDate, '0001-01-01'), 
                    wCalendarType = 'Solar', 
                    wYear  = ISNULL(YEAR(ma.wBirthDate),  1), 
                    wMonth = ISNULL(MONTH(ma.wBirthDate), 1), 
                    wDay   = ISNULL(DAY(ma.wBirthDate),   1), 
                    wIsLeapMonth = 'N',
                    wContactWay  = NULL, 
                    wTelNumber   = ma.wTel, 
                    wWhatsappNumber  = ma.wWhatsapp, 
                    wWeChatNumber    = ma.wWeChat, 
                    wWeChatName      = NULL, 
                    wBudgetRatio     = 0, 
                    wIsWeChatVerify  = 'N', 
                    wIsPresentGift   = 'N',
                    wIsAuthorizer    = 'Y',
                    wVIPPersonStatus = 'A', 
                    wStatusRemark    = NULL,
                    wSource          = '001',
                    wIsRefusedContact = 'N',
                    wStatus = 'A',
                    wCrtBy = @sUpdBy, 
                    wCrtDt = @sNow, 
                    wUpdBy = @sUpdBy, 
                    wUpdDt = @sNow
                FROM RollsMary.dbo.mAgent ma
                INNER JOIN RollsMary.dbo.mAgent lvlma ON lvlma.wAgentCodeIn = ma.wUpLvlAgentCodeIn
                LEFT JOIN dbo.mVIPPerson mp ON mp.wAgentCodeIn = ma.wUpLvlAgentCodeIn AND mp.wAuthorizerAgentCodeIn = ma.wAgentCodeIn AND mp.wIsAuthorizer = 'Y' AND mp.wStatus = 'A'
                WHERE mp.RowID IS NULL
                    AND ma.wStatus = 'A'
                    AND ma.wType = 'AUTH'
                    AND ma.wAuthIdentity NOT IN ('ASSISTANT', 'MARKETING', 'DIRECTOR') -- 不包含業務發展部助理、市場部、總監
                    AND lvlma.wType = 'AGENT'
                    AND lvlma.wStatus = 'A'
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = ma.wUpLvlAgentCodeIn) -- 戶口
                    AND (@pAuthorizerAgentCodeIn IS NULL OR @pAuthorizerAgentCodeIn = ma.wAgentCodeIn) -- 授權人
                OPTION(RECOMPILE);
                
                -- 獲取每個戶口的第一個VIP、MD跟進部門，VIP跟進優先
                INSERT INTO @vAgentFollow(wAgentCodeIn, wFollowDept)
                SELECT af.wAgentCodeIn, 
                       af.wFollowDept
                FROM (
                    SELECT wRowNum = ROW_NUMBER() OVER (PARTITION BY af.wAgentCodeIn ORDER BY md.wCode DESC, afd.wIsMainInCharge DESC),
                           af.wAgentCodeIn,
                           wFollowDept = IIF(md.wCode = 'DEVELOP', 'MD', 'VIP')
                    FROM RollsMary.dbo.mAgentFollow af
                    INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
                    INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
                    INNER JOIN #vVIPPerson mp ON mp.wAgentCodeIn = af.wAgentCodeIn
                    WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
                        AND NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A'
                        AND md.wCode IN ('HOUSEKEEPER', 'DEVELOP') AND md.wActive = 'A' -- 只需要取VIP（HOUSEKEEPER）、MD（DEVELOP）跟進
                ) AS af WHERE af.wRowNum = 1 -- 取每一個戶口的第一人跟進人（順序：VIP主負責人、VIP跟進人、MD主負責人、MD跟進人）
                OPTION(RECOMPILE);
                
                -- T掉不是VIP、MD跟進的戶口
                WITH tAgentIdentity AS (
                    SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY mi.wAgentCodeIn ORDER BY mi.wAgentCodeIn, ai.wType),
                           mi.wAgentCodeIn, 
                           ai.wType
                    FROM RollsMary.dbo.mAgentIdentity mi 
                    INNER JOIN @vAgentIdentity ai ON ai.wType = mi.wType
                    WHERE mi.wValue = 'Y'
                )

                UPDATE mp
                SET mp.wStatus = IIF( ma.wAgentType = 'GAMBLERS' AND af.wFollowDept = 'MD' AND mi.wType IS NULL, 'U', 'T') -- 如果是玩家，MD跟進，非星級、高度重視客戶，未能確定是否批額客戶，先把狀態設為'U'，后面進一步確認
                FROM #vVIPPerson mp
                INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAuthorizerAgentCodeIn -- 授權人
                LEFT JOIN tAgentIdentity mi ON mi.wAgentCodeIn = ma.wAgentCodeIn AND mi.RowNum = 1
                LEFT JOIN @vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn
                WHERE af.wAgentCodeIn IS NULL OR (af.wFollowDept = 'MD' AND (ma.wAgentType != 'GAMBLERS' OR mi.wType IS NULL));
                
                -- Check批額客戶
                SET @sInXML = (SELECT wAgentCodeIn = wAuthorizerAgentCodeIn FROM #vVIPPerson WHERE wStatus = 'U' FOR XML RAW('Record'), ROOT('DataSet'));
                EXEC util.RecalVIPPersonForCredit @sInXML, @sOutXML OUTPUT;
                
                IF @sOutXML IS NOT NULL
                BEGIN
                    INSERT INTO #vAgentCredit(wAgentCodeIn)
                    SELECT DISTINCT wAgentCodeIn = T.tmp.value('@wAgentCodeIn', 'VARCHAR(14)')
                    FROM @sOutXML.nodes('DataSet/Record') T(tmp)
                    WHERE NULLIF(T.tmp.value('@wAgentCodeIn', 'VARCHAR(14)'), '') IS NOT NULL;
                END;

                UPDATE mp
                SET mp.wStatus = IIF(ac.wAgentCodeIn IS NOT NULL, 'A', 'T')
                FROM #vVIPPerson mp
                LEFT JOIN #vAgentCredit ac ON ac.wAgentCodeIn = mp.wAuthorizerAgentCodeIn
                WHERE mp.wStatus = 'U';
                
                -- 刪除wStatus <> 'A'的Record不要Insert到mVIPPerson
                DELETE FROM #vVIPPerson WHERE wStatus <> 'A';

                -- Set MD跟進 VIP客戶身份
                UPDATE mp
                SET mp.wPersonIdentity = 'MD_CLIENT' -- MD星級客戶
                FROM #vVIPPerson mp
                INNER JOIN @vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn
                WHERE af.wFollowDept = 'MD';
                
                -- Set #vVIPPerson RowNum
                UPDATE mp 
                SET wRowNum = smp.wRowNum
                FROM #vVIPPerson mp
                INNER JOIN ( 
                    SELECT wRowNum = ROW_NUMBER() OVER(ORDER BY wAgentCodeIn, wAuthorizerAgentCodeIn),
                           wAgentCodeIn,
                           wAuthorizerAgentCodeIn
                    FROM #vVIPPerson
                ) smp ON smp.wAgentCodeIn = mp.wAgentCodeIn AND smp.wAuthorizerAgentCodeIn = mp.wAuthorizerAgentCodeIn
        
                -- 授權人設置佐拒絕接觸拒絕接觸
                -- 拒絕接觸 -> 如果 mAgentIdentity.wDeptRid= '27'（VIP跟進） and wType ='DENY_CONTACT', 戶口就要預設「拒絕接觸」checkbox為剔
                UPDATE mp
                SET wIsRefusedContact = 'Y'
                FROM #vVIPPerson mp
                INNER JOIN RollsMary.dbo.mAgentIdentity mi ON mi.wAgentCodeIn = mp.wAuthorizerAgentCodeIn
                WHERE mi.wDeptRid = @sVIPDeptRid 
                    AND mi.wType = 'DENY_CONTACT' 
                    AND mi.wValue = 'Y';
    
                SET @sRecCount = (SELECT COUNT(1) FROM #vVIPPerson);
                SET @sRowIndex = 1;

                WHILE @sRowIndex <= @sRecCount
                BEGIN
                    EXEC spq.GetRowID 99, @sThisTableName, @sRowID OUTPUT
                    
                    UPDATE #vVIPPerson
                    SET RowID = @sRowID 
                    WHERE wRowNum = @sRowIndex;
               
                    SET @sRowIndex = @sRowIndex + 1;
                END;

                -- VIP客戶資料
                INSERT INTO [dbo].[mVIPPerson]
                (
                    RowID, 
                    wAgentCodeIn,
                    wPersonName, 
                    wPersonIdentity, 
                    wGender, 
                    wAuthorizerAgentCodeIn, 
                    wAuthorizerIdentity, 
                    wRelationship, 
                    wOtherRelationship,
                    wBirthDate, 
                    wCalendarType, 
                    wYear, 
                    wMonth, 
                    wDay, 
                    wIsLeapMonth,
                    wContactWay, 
                    wTelNumber, 
                    wWhatsappNumber, 
                    wWeChatNumber, 
                    wWeChatName, 
                    wBudgetRatio, 
                    wIsWeChatVerify, 
                    wIsPresentGift,
                    wIsAuthorizer,
                    wVIPPersonStatus, 
                    wStatusRemark,
                    wSource,
                    wIsRefusedContact,
                    wStatus, 
                    wCrtBy, 
                    wCrtDt, 
                    wUpdBy, 
                    wUpdDt 
                )
                SELECT
                    RowID, 
                    wAgentCodeIn,
                    wPersonName, 
                    wPersonIdentity, 
                    wGender, 
                    wAuthorizerAgentCodeIn, 
                    wAuthorizerIdentity, 
                    wRelationship, 
                    wOtherRelationship,
                    wBirthDate, 
                    wCalendarType, 
                    wYear, 
                    wMonth, 
                    wDay, 
                    wIsLeapMonth,
                    wContactWay, 
                    wTelNumber, 
                    wWhatsappNumber, 
                    wWeChatNumber, 
                    wWeChatName, 
                    wBudgetRatio, 
                    wIsWeChatVerify, 
                    wIsPresentGift,
                    wIsAuthorizer,
                    wVIPPersonStatus, 
                    wStatusRemark,
                    wSource,
                    wIsRefusedContact,
                    wStatus, 
                    wCrtBy, 
                    wCrtDt, 
                    wUpdBy, 
                    wUpdDt
                FROM #vVIPPerson;
        
                -- 相關戶口（自己關聯到自己，默認要生成生日記錄）
                INSERT INTO dbo.eVIPPersonShip(
                    wVIPPersonRid,
                    wVIPPersonRefRid,
                    wIsBirthday,
                    wUpdBy,
                    wUpdDt
                )
                SELECT
                    wVIPPersonRid = RowID,
                    wVIPPersonRefRid  = RowID,
                    wIsBirthday = 'Y',
                    wUpdBy,
                    wUpdDt
                FROM #vVIPPerson
            END;
        
            -- 更新客戶資料
            IF @pActionType = 'U'
            BEGIN
                -- 更新授權人基本資料(wStatus='A')
                UPDATE mp
                SET wAgentCodeIn = ma.wUpLvlAgentCodeIn,
                    wPersonName = ma.wCName, 
                    wPersonIdentity = IIF(ma.wAuthIdentity = 'OWNER' OR ma.wAuthIdentity = 'BOSS', CONCAT('VIP', '_', ma.wAuthIdentity), 'VIP_CLIENT'), -- OWNER --> VIP_OWNER(VIP戶主)、BOSS --> VIP_BOSS（VIP幕後老闆）、其他 --> VIP_CLIENT(VIP客戶)
                    wGender = ma.wSex, 
                    wAuthorizerAgentCodeIn = ma.wAgentCodeIn, 
                    wAuthorizerIdentity = ma.wAuthIdentity, 
                    wBirthDate = ISNULL(ma.wBirthDate, '0001-01-01'), 
                    wYear      = IIF(mp.wCalendarType <> 'Solar' OR mp.wYear <> YEAR(mp.wBirthDate) OR mp.wMonth <> MONTH(mp.wBirthDate) OR mp.wDay <> DAY(mp.wBirthDate), mp.wYear,  ISNULL(YEAR(ma.wBirthDate),  1)),
                    wMonth     = IIF(mp.wCalendarType <> 'Solar' OR mp.wYear <> YEAR(mp.wBirthDate) OR mp.wMonth <> MONTH(mp.wBirthDate) OR mp.wDay <> DAY(mp.wBirthDate), mp.wMonth, ISNULL(MONTH(ma.wBirthDate), 1)),
                    wDay       = IIF(mp.wCalendarType <> 'Solar' OR mp.wYear <> YEAR(mp.wBirthDate) OR mp.wMonth <> MONTH(mp.wBirthDate) OR mp.wDay <> DAY(mp.wBirthDate), mp.wDay,   ISNULL(DAY(ma.wBirthDate),   1)),
                    wTelNumber = ma.wTel, 
                    wWhatsappNumber = ma.wWhatsapp, 
                    wWeChatNumber = ma.wWeChat
                FROM dbo.mVIPPerson mp
                INNER JOIN RollsMary.dbo.mAgent ma ON ma.wUpLvlAgentCodeIn = mp.wAgentCodeIn AND ma.wAgentCodeIn = mp.wAuthorizerAgentCodeIn AND mp.wIsAuthorizer = 'Y' AND mp.wStatus = 'A'
                WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn) 
                    AND (@pAuthorizerAgentCodeIn IS NULL OR @pAuthorizerAgentCodeIn = mp.wAuthorizerAgentCodeIn);

                -- 授權人設置佐拒絕接觸拒絕接觸
                -- 拒絕接觸 -> 如果 mAgentIdentity.wDeptRid= '27'（VIP跟進） and wType ='DENY_CONTACT', 戶口就要預設「拒絕接觸」checkbox為剔
                UPDATE mp
                SET wIsRefusedContact = 'Y'
                FROM dbo.mVIPPerson mp
                INNER JOIN RollsMary.dbo.mAgentIdentity mi ON mi.wAgentCodeIn = mp.wAuthorizerAgentCodeIn AND mp.wIsAuthorizer = 'Y' AND mp.wStatus = 'A'
                WHERE (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn) 
                    AND (@pAuthorizerAgentCodeIn IS NULL OR @pAuthorizerAgentCodeIn = mp.wAuthorizerAgentCodeIn)
                    AND mi.wDeptRid = @sVIPDeptRid 
                    AND mi.wType = 'DENY_CONTACT' 
                    AND mi.wValue = 'Y';

                --------------------------------------------------------------------------------------------------------
                -- 獲取每個戶口的第一個VIP、MD跟進部門，VIP跟進優先
                INSERT INTO @vAgentFollow(wAgentCodeIn, wFollowDept)
                SELECT af.wAgentCodeIn, 
                       af.wFollowDept
                FROM (
                    SELECT wRowNum = ROW_NUMBER() OVER (PARTITION BY af.wAgentCodeIn ORDER BY md.wCode DESC, afd.wIsMainInCharge DESC),
                           af.wAgentCodeIn,
                           wFollowDept = IIF(md.wCode = 'DEVELOP', 'MD', 'VIP')
                    FROM RollsMary.dbo.mAgentFollow af
                    INNER JOIN RollsMary.dbo.mAgentFollowDtl afd ON afd.wAgentFollowRid = af.RowID
                    INNER JOIN RollsMary.dbo.mDepartment md ON md.RowID = af.wDeptRid
                    INNER JOIN dbo.mVIPPerson mp ON mp.wAgentCodeIn = af.wAgentCodeIn
                    WHERE NULLIF(af.wYearMth, '') IS NULL AND af.wStatus = 'A'
                        AND NULLIF(afd.wYearMth, '') IS NULL AND afd.wStatus = 'A'
                        AND md.wCode IN ('HOUSEKEEPER', 'DEVELOP') AND md.wActive = 'A' -- 只需要取VIP（HOUSEKEEPER）、MD（DEVELOP）跟進
                        AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn) 
                        AND (@pAuthorizerAgentCodeIn IS NULL OR @pAuthorizerAgentCodeIn = mp.wAuthorizerAgentCodeIn)
                ) AS af WHERE af.wRowNum = 1 -- 取每一個戶口的第一人跟進人（順序：VIP主負責人、VIP跟進人、MD主負責人、MD跟進人）
                OPTION(RECOMPILE);
                
                -- T掉不是VIP、MD跟進的戶口
                -- T掉MD跟進，非玩家--> 星級、重視戶口、批額
                -- 條件：沒有生日送禮，有生日送禮，但未批核、未送出
                 WITH tBirthday AS (
                    SELECT RowNum = ROW_NUMBER() OVER(PARTITION BY wVIPPersonRid ORDER BY wApprovedStatus DESC, wGiftStatus DESC),
                           RowID,
                           wVIPPersonRid,
                           wApprovedStatus,
                           wGiftStatus
                    FROM dbo.eBirthday
                    WHERE wStatus = 'A'
                ),
                tAgentIdentity AS (
                    SELECT RowNum = ROW_NUMBER() OVER (PARTITION BY mi.wAgentCodeIn ORDER BY mi.wAgentCodeIn, ai.wType),
                           mi.wAgentCodeIn, 
                           ai.wType
                    FROM RollsMary.dbo.mAgentIdentity mi 
                    INNER JOIN @vAgentIdentity ai ON ai.wType = mi.wType
                    WHERE mi.wValue = 'Y'
                )

                UPDATE mp
                SET mp.wStatus = IIF( ma.wAgentType = 'GAMBLERS' AND af.wFollowDept = 'MD' AND mi.wType IS NULL, 'U', 'T') -- 如果是玩家，MD跟進，非星級、高度重視客戶，未能確定是否批額客戶，先把狀態設為'U'，后面進一步確認
                FROM dbo.mVIPPerson mp
                INNER JOIN RollsMary.dbo.mAgent ma ON ma.wAgentCodeIn = mp.wAuthorizerAgentCodeIn -- 授權人
                LEFT JOIN tAgentIdentity mi ON mi.wAgentCodeIn = ma.wAgentCodeIn AND mi.RowNum = 1
                LEFT JOIN tBirthday eb ON eb.wVIPPersonRid = mp.RowID AND eb.RowNum = 1
                LEFT JOIN @vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn
                WHERE mp.wStatus = 'A'
                    AND mp.wIsAuthorizer = 'Y'
                    AND (@pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn) 
                    AND (@pAuthorizerAgentCodeIn IS NULL OR @pAuthorizerAgentCodeIn = mp.wAuthorizerAgentCodeIn)
                    AND (eb.RowID IS NULL OR (eb.wApprovedStatus = 'N' AND eb.wGiftStatus = 'N'))-- 未批核，未送出
                    AND (af.wAgentCodeIn IS NULL OR (af.wFollowDept = 'MD' AND (ma.wAgentType != 'GAMBLERS' OR mi.wType IS NULL)));

                -- Check批額客戶
                SET @sInXML = (SELECT wAgentCodeIn = wAuthorizerAgentCodeIn FROM dbo.mVIPPerson WHERE wStatus = 'U' FOR XML RAW('Record'), ROOT('DataSet'));
                EXEC util.RecalVIPPersonForCredit @sInXML, @sOutXML OUTPUT;
                
                IF @sOutXML IS NOT NULL
                BEGIN
                    INSERT INTO #vAgentCredit(wAgentCodeIn)
                    SELECT DISTINCT wAgentCodeIn = T.tmp.value('@wAgentCodeIn', 'VARCHAR(14)')
                    FROM @sOutXML.nodes('DataSet/Record') T(tmp)
                    WHERE NULLIF(T.tmp.value('@wAgentCodeIn', 'VARCHAR(14)'), '') IS NOT NULL;
                END;

                UPDATE mp
                SET mp.wStatus = IIF(ac.wAgentCodeIn IS NOT NULL, 'A', 'T')
                FROM dbo.mVIPPerson mp
                LEFT JOIN #vAgentCredit ac ON ac.wAgentCodeIn = mp.wAuthorizerAgentCodeIn
                WHERE mp.wStatus = 'U';

                -- 把MD跟進戶口授權人設置為MD星級客戶
                UPDATE mp
                SET mp.wPersonIdentity = 'MD_CLIENT'
                FROM dbo.mVIPPerson mp
                INNER JOIN @vAgentFollow af ON af.wAgentCodeIn = mp.wAgentCodeIn
                WHERE mp.wStatus = 'A'
                    AND mp.wIsAuthorizer = 'Y' 
                    AND af.wFollowDept = 'MD';
                --------------------------------------------------------------------------------------------------------
            END;

            IF @sBeginTranCount = 0 AND @@trancount > 0
            BEGIN
                COMMIT;
            END;

        END TRY
        BEGIN CATCH
            DECLARE @sErrorNum INT ,
                    @sCatchErrorMessage NVARCHAR(4000) ,
                    @xstate INT ,
                    @sProcedureName VARCHAR(100) ,
                    @sRtnCodeLog INT ,
                    @sErrMessageLog NVARCHAR(4000);
	        
            SELECT  @sErrorNum = ERROR_NUMBER() ,
                    @sCatchErrorMessage = ERROR_MESSAGE() ,
                    @xstate = XACT_STATE() ,
                    @sProcedureName = OBJECT_NAME(@@PROCID);
			
            IF ISNULL(@sErrCode, 0) = 0
                SET @sErrCode = 70001;

            IF NULLIF(@sErrMsg, '') IS NULL
                SET @sErrMsg = CONCAT('(', @sErrorNum, ') ', @sCatchErrorMessage);
			
            PRINT @sErrMsg;

            IF @sBeginTranCount = 0
            BEGIN
                IF @xstate != 0
                    ROLLBACK;

                -- Write Log
                EXEC spa.WriteErrorLog 99, 99, @sProcedureName, @sErrMsg, @sRtnCodeLog OUTPUT, @sErrMessageLog OUTPUT;
            END
            ELSE
                THROW @sErrCode, @sErrMsg, 1;  

        END CATCH;

        IF OBJECT_ID('tempdb..#vAgentCredit') IS NOT NULL
            DROP TABLE #vAgentCredit;

        IF OBJECT_ID('tempdb..#vVIPPerson') IS NOT NULL
            DROP TABLE #vVIPPerson;
    END;