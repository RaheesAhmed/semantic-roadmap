

CREATE PROCEDURE [spq].[GetRptCounterLog]
(
    @pCounterRid VARCHAR(MAX) ,
    @pFromDt DATETIME2(7),
    @pToDt DATETIME2(7),
    @pType VARCHAR(1000),
    @pLangCd VARCHAR(10) = 'zh-TW'
)
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SET @pFromDt = FORMAT(@pFromDt, 'yyyy-MM-dd 00:00:00');
        SET @pToDt = FORMAT(@pToDt, 'yyyy-MM-dd 23:59:59');
        SET @pLangCd = ISNULL(@pLangCd, 'zh-tw');
        SET @pCounterRid= ISNULL(@pCounterRid, '');
        SET @pType= ISNULL(@pType, '');		

        -- 場館
        DECLARE @tmpFilterpCounter AS TABLE ( wCounterRid  BIGINT );
        IF @pCounterRid != '' BEGIN
            INSERT INTO @tmpFilterpCounter(wCounterRid) SELECT CAST(item AS BIGINT) FROM dbo.fnSplit(@pCounterRid, ',');
        END;

        DECLARE @tmpFilterType AS TABLE ( wType VARCHAR(1000) );
        IF @pType != '' BEGIN
            INSERT INTO @tmpFilterType(wType) SELECT item FROM dbo.fnSplit(@pType, ',');
        END;
		CREATE TABLE #tResult 
        (
             wTitle NVARCHAR(500),
             wLogStatus NVARCHAR(50),
             wDeptName NVARCHAR(50),
             wCounterName NVARCHAR(30),
             wContent NVARCHAR(4000),
             wUsrName NVARCHAR(40),
             wDateTime DATETIME2(7),
             wRelateAgentName NVARCHAR(70),
             wRelatePersonName NVARCHAR(500),
             wRoleName NVARCHAR(50),
             wType NVARCHAR(50)
        );

        IF @pType='' OR EXISTS(SELECT 1 FROM @tmpFilterType WHERE wType IN('13', '14','15','16','17','20','21','25','29','30','31'))
        BEGIN
            INSERT INTO #tResult(
                wTitle,
                wLogStatus,
                wDeptName,
                wCounterName,
                wContent,
                wUsrName,
                wDateTime,
                wRelateAgentName,
                wRelatePersonName,
                wRoleName,
                wType
            )
            SELECT
                eLog.wTitle,
                wLogStatus = eLog.wIsProcessed,
                wDeptName = CASE WHEN @pLangCd = 'en-GB' THEN mDep.wEName ELSE mDep.wCName END,
                wCounterName = tCounter.wName,
                eLog.wContent,
                wUsrName = CASE WHEN @pLangCd = 'en-GB' THEN mcUsr.wName ELSE mcUsr.wCName END,
                eLog.wDateTime,
                wRelateAgentName = CONCAT(tAgent.wAgentCode_Display, '(', CASE WHEN @pLangCd = 'en-GB' THEN tAgent.wEName ELSE tAgent.wCName END,  ')'),
                wRelatePersonName = CASE WHEN @pLangCd = 'en-GB' THEN mP.wEName ELSE mP.wCName END,
                wRoleName = mR.wTitle,
                eLog.wType
            FROM [dbo].[eCounterLog] eLog
            LEFT JOIN [RollsMary].[dbo].[mAgent] tAgent ON tAgent.wAgentCodeIn = eLog.wRelateAgentCodeIn
            LEFT JOIN [CRM].[dbo].mServiceCounter tCounter ON tCounter.RowID = eLog.wCounterRid
            LEFT JOIN [RollsMary].[dbo].[mUsr] mcUsr ON mcUsr.RowID = eLog.wCrtBy
            LEFT JOIN [CRM].[dbo].mPerson mP ON mP.RowID = eLog.wRelatePersonRid 
            LEFT JOIN RollsMary.dbo.mDepartment mDep ON wIsRealDept = 'Y' AND NULLIF(wUserLineGrp, '') IS NULL AND wActive = 'A' AND mDep.wCode = eLog.wDeptCd
            LEFT JOIN [dbo].[mLookUp] mR ON mR.wCode = mp.wRole  AND mR.wLangCd = @pLangCd AND mR.wType = 'PERSON_ROLE'
            LEFT JOIN @tmpFilterpCounter AS dcfil ON dcfil.wCounterRid =ISNULL(eLog.wCounterRid, 0) 
            LEFT JOIN @tmpFilterType AS regfil ON regfil.wType = eLog.wType
            WHERE eLog.wStatus = 'A'
                AND (@pCounterRid = '' OR dcfil.wCounterRid IS NOT NULL)
                AND ((@pFromDt IS NULL OR @pFromDt <= eLog.wCrtDt) AND (@pToDt IS NULL OR  eLog.wCrtDt <= @pToDt))
                AND (@pType = '' OR regfil.wType IS NOT NULL)
                AND eLog.wType IN('13', '14','15','16','17','20','21','25','29','30','31')
        END;
        IF @pType='' OR CHARINDEX('001', @pType) > 0 --勾选了不达标
        BEGIN
            INSERT INTO #tResult(
                wTitle,
                wLogStatus,
                wDeptName,
                wCounterName,
                wContent,
                wUsrName,
                wDateTime,
                wRelateAgentName,
                wRelatePersonName,
                wRoleName,
                wType
            )
            SELECT
                wTitle = ml.wTitle + '-' + mlp.wTitle,
                wLogStatus = mlu.wTitle,
                wDeptName =  CASE WHEN @pLangCd = 'en-GB' THEN mDep.wEName ELSE mDep.wCName END,
                wCounterName = tCounter.wName,
                wContent = eUnq.wDetails + eUnq.wFollowUpDetails,
                wUsrName = CASE WHEN @pLangCd = 'en-GB' THEN mcUsr.wName ELSE mcUsr.wCName END,
                wDateTime = eUnq.wCrtDt,
                wRelateAgentName = CONCAT(tAgent.wAgentCode_Display, '(', CASE WHEN @pLangCd = 'en-GB' THEN tAgent.wEName ELSE tAgent.wCName END, ')'),
                wRelatePersonName = '',
                wRoleName = '',
                wType = eUnq.wUnqualifiedType
            FROM [dbo].[eUnqualified] eUnq
            LEFT JOIN [CRM].[dbo].mServiceCounter tCounter ON tCounter.RowID = eUnq.wCounterRid
            LEFT JOIN [RollsMary].[dbo].[mAgent] tAgent ON tAgent.wAgentCodeIn = eUnq.wAgentCodeIn
            LEFT JOIN [RollsMary].[dbo].[mUsr] mcUsr ON mcUsr.RowID = eUnq.wCrtBy
            LEFT JOIN RollsMary.dbo.mDepartment mDep ON wIsRealDept = 'Y' AND NULLIF(wUserLineGrp, '') IS NULL AND wActive = 'A' AND mDep.wCode = eUnq.wDeptCd
            LEFT JOIN @tmpFilterpCounter AS dcfil ON dcfil.wCounterRid =ISNULL(eUnq.wCounterRid, 0)
            LEFT JOIN mLookup ml ON ml.wCode=eUnq.wUnqualifiedType AND ml.wLangCd = @pLangCd AND ml.wType='UNQUALIFIED_TYPE'   
            LEFT JOIN mLookup mlp ON mlp.wCode=eUnq.wReason AND mlp.wLangCd = @pLangCd AND mlp.wType='UNQUALIFIED_REASON'
            LEFT JOIN mLookup mlu ON mlu.wCode=eUnq.wUnqualifiedStatus AND mlu.wLangCd=@pLangCd AND mlu.wType='UNQUALIFIED_STATUS'
            WHERE eUnq.wStatus = 'A' 
                AND	(@pCounterRid = '' OR dcfil.wCounterRid IS NOT NULL )								
                AND ((@pFromDt IS NULL OR @pFromDt <= eUnq.wCrtDt) AND (@pToDt IS NULL OR  eUnq.wCrtDt <= @pToDt))
                AND eUnq.wUnqualifiedType = '08'
        END;
        IF @pType='' OR CHARINDEX('002', @pType) > 0 --勾选了车务不达标
        BEGIN
            WITH tmpMACAUCOMPLETED AS (
                SELECT COUNT(1) AS MACAUCOMPLETED
                FROM [RollsMary].[dbo].[eLimoOrder]
                WHERE wDomainCd='MACAU' AND wStatus='COMPLETED' AND ((@pFromDt IS NULL OR @pFromDt <= wStartDate) AND (@pToDt IS NULL OR  wStartDate <= @pToDt))
            ),
            tmpMACAUFAILED AS (
                SELECT COUNT(1) AS MACAUFAILED
                FROM [RollsMary].[dbo].[eLimoOrder]
                WHERE wDomainCd='MACAU' AND wStatus='FAILED ' AND ((@pFromDt IS NULL OR @pFromDt <= wCreateDateTime) AND (@pToDt IS NULL OR  wCreateDateTime <= @pToDt))
                ),
            tmpMACOMPLETED AS(
                SELECT COUNT(1)AS MACOMPLETED
                FROM [RollsMary].[dbo].[eLimoOrder]
                WHERE wDomainCd='MANILA' AND wStatus='COMPLETED' AND ((@pFromDt IS NULL OR @pFromDt <= wStartDate) AND (@pToDt IS NULL OR  wStartDate <= @pToDt))
            ),
            tmpMAFAILED AS (
                SELECT COUNT(1) AS MAFAILED
                FROM [RollsMary].[dbo].[eLimoOrder]
                WHERE wDomainCd='MANILA' AND wStatus='FAILED ' AND ((@pFromDt IS NULL OR @pFromDt <= wCreateDateTime) AND (@pToDt IS NULL OR  wCreateDateTime <= @pToDt))
            )
            INSERT INTO #tResult(
                wTitle,
                wLogStatus,
                wDeptName,
                wCounterName,
                wContent,
                wUsrName,
                wDateTime,
                wRelateAgentName,
                wRelatePersonName,
                wRoleName,
                wType
            )
            SELECT 				
                '' AS wTitle,
                '' AS wLogStatus,
                '' AS wDeptName,
                '' AS wCounterName,
                CONVERT(VARCHAR(10),TP3.MACOMPLETED)+','+CONVERT(VARCHAR(10),TP4.MAFAILED)+ ','+CONVERT(VARCHAR(10),TP1.MACAUCOMPLETED)+','+CONVERT(VARCHAR(10),TP2.MACAUFAILED)AS wContent,
                '' AS wUsrName,
                '' AS wDateTime,
                '' AS wRelateAgentName,
                '' AS wRelatePersonName,
                '' AS wRoleName,
                '002' AS wType
                FROM tmpMACAUCOMPLETED TP1,tmpMACAUFAILED TP2,tmpMACOMPLETED TP3,tmpMAFAILED TP4          
        END;
        IF @pType='' OR CHARINDEX('003', @pType) > 0 --勾选投诉管理
        BEGIN
            INSERT INTO #tResult(
                wTitle,
                wLogStatus,
                wDeptName,
                wCounterName,
                wContent,
                wUsrName,
                wDateTime,
                wRelateAgentName,
                wRelatePersonName,
                wRoleName,
                wType
            )
            SELECT
                m.wTitle,
                wLogStatus = p.wTitle,
                wDeptName = CASE WHEN @pLangCd = 'en-GB' THEN mDep.wEName ELSE mDep.wCName END,
                wCounterName = c.wReceivedLocation,
                c.wContent ,
                wUsrName = CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName ELSE crusr.wCName END,
                wDateTime = c.wCrtDt,                                       
                wRelateAgentName = CONCAT(tAgent.wAgentCode_Display, '(', CASE WHEN @pLangCd = 'en-GB' THEN tAgent.wEName ELSE tAgent.wCName END, ')'),
                '' AS wRelatePersonName,
                '' AS wRoleName,
                '003' AS wType
            FROM dbo.eComplaint c
            LEFT JOIN dbo.mLookUp m ON m.wCode = c.wType AND m.wLangCd = @pLangCd AND m.wType='COMPLAINT_CATEGORY'
            LEFT JOIN dbo.mLookUp p ON p.wCode = c.wComplaintStatus AND p.wLangCd = @pLangCd AND p.wType='OTHER_COMPLAINT'
            LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = c.wCrtBy
            LEFT JOIN RollsMary.dbo.mDepartment mDep ON wIsRealDept = 'Y' AND NULLIF(wUserLineGrp, '') IS NULL AND wActive = 'A' AND mDep.wCode =c.wReceivedDeptCd
            LEFT JOIN [RollsMary].[dbo].[mAgent] tAgent ON tAgent.wAgentCodeIn = c.wAgentCodeIn
            WHERE ((@pFromDt IS NULL OR @pFromDt <= c.wCrtDt) AND (@pToDt IS NULL OR c.wCrtDt <= @pToDt))
        END;         							       
        SELECT * FROM #tResult ORDER BY wType
        IF OBJECT_ID('tempdb..#tResult') IS NOT NULL BEGIN
			DROP TABLE #tResult;
		END	       
    END;