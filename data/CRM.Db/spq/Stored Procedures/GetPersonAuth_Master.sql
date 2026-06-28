
CREATE PROCEDURE [spq].[GetPersonAuth_Master]
(
    @pAgentCodeIn VARCHAR(14) ,
    @pCName NVARCHAR(50) ,
    @pEName NVARCHAR(500) ,
    @pEnglishPinyin VARCHAR(100),
    @pIDNo VARCHAR(30) ,
    @pRole NCHAR(10) ,
    @pStatus CHAR(1) ,
    @pSort VARCHAR(200) ,
    @pLangCd VARCHAR(30) ,
    @pPageNum INT,
    @pPageSize INT
)
AS
    BEGIN   
        SET NOCOUNT ON;

        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pCName = NULLIF(@pCName, '');
        SET @pEName = NULLIF(@pEName, '');
        SET @pEnglishPinyin = NULLIF(@pEnglishPinyin, '');
        SET @pIDNo = NULLIF(@pIDNo, '');
        SET @pRole = NULLIF(@pRole, '');
        SET @pStatus = NULLIF(@pStatus, ' ');
        SET @pSort = ISNULL(NULLIF(@pSort, ''), '||');
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 20);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);	

        WITH
        tPersonTravelDocGroup AS (
            SELECT
                rptd.wPersonRID
            FROM dbo.mPersonTravelDoc AS rptd
            WHERE (@pEnglishPinyin IS NULL OR wEnglishPinyin = @pEnglishPinyin)
                AND (@pIDNo IS NULL OR wIDNo = @pIDNo)
            GROUP BY rptd.wPersonRID
        ),
        tPerson AS (  
            SELECT
                mp.RowID ,
                wIsAuth = IIF( mp.wRefRID IS NULL, 'N', 'Y') ,
                wAgentCodeIn = IIF( mp.wRefRID IS NULL, mp.wAgentCodeIn, auth.wUpLvlAgentCodeIn) ,
                wAgentCodeIn_I = IIF( mp.wRefRID IS NULL, mp.wAgentCodeIn, auth.wAgentCodeIn ),
                wCName = IIF( mp.wRefRID IS NULL, mp.wCName, auth.wCName ) ,
                wEName = IIF( mp.wRefRID IS NULL, mp.wEName, auth.wEName ),
                wNickname = IIF( mp.wRefRID IS NULL , mp.wNickname, auth.wNickName ),
                mp.wRole ,
                mp.wSpeakLangCd ,
                mp.wWritenLangCd ,
                wGender = IIF( mp.wRefRID IS NULL, mp.wGender, auth.wSex ),
                wBirthdate = IIF( mp.wRefRID IS NULL, mp.wBirthdate, auth.wBirthDate ),
                wNationality = IIF( mp.wRefRID IS NULL, mp.wNationality, auth.wNationality ),
                wProvince = IIF( mp.wRefRID IS NULL, mp.wProvince, auth.wProvince ),
                wAddress = IIF( mp.wRefRID IS NULL, mp.wAddress, auth.wAddress ) ,
                mp.wTelBusiness ,
                mp.wTelHome ,
                mp.wTelOther ,
                mp.wRefRID ,
                mp.wStatus ,
                wCrtDt = IIF( mp.wRefRID IS NULL, mp.wCrtDt, auth.wCreateDate ),
                wCrtBy = IIF( mp.wRefRID IS NULL, mp.wCrtBy, auth.wCrtby ) ,
                wUpdDt = IIF( mp.wRefRID IS NULL, mp.wUpdDt, auth.wUpdDt ),
                wUpdBy = IIF( mp.wRefRID IS NULL, mp.wUpdBy, auth.wUpdBy ),
                wQuantityOfTravelDoc = 0 ,
                wEnglishPinyinInDoc = '' ,
                wIDTypeInDoc = '' ,
                wIDNoInDoc = '' ,
                wIssueAtInDoc = '' ,
                wExpiryDateInDoc = '' ,
                wRefRIDInDoc = 'N'
            FROM dbo.mPerson mp
            LEFT JOIN RollsMary.dbo.mAgent auth ON auth.RowID = mp.wRefRID AND auth.wType = 'AUTH' AND auth.wAuthIdentity IN ( 'AUTH'/*授權人*/, 'BOSS'/*幕後老闆*/, 'OWNER'/*戶主*/, 'DIRECTOR'/*總監*/, 'STAFF'/*伙記*/, 'PARTNER' /*拍檔*/ )
            LEFT JOIN tPersonTravelDocGroup AS ptd ON ptd.wPersonRID = mp.RowID
            WHERE ( @pAgentCodeIn IS NULL
                    OR ( mp.wRefRID IS NULL AND @pAgentCodeIn = mp.wAgentCodeIn )
                    OR ( mp.wRefRID IS NOT NULL AND @pAgentCodeIn = auth.wAgentCodeIn ))
                AND ( @pCName IS NULL
                    OR ( mp.wRefRID IS NULL AND @pCName = mp.wCName )
                    OR ( mp.wRefRID IS NOT NULL AND @pCName = auth.wCName ))
                AND ( @pEName IS NULL
                    OR ( mp.wRefRID IS NULL AND @pEName = mp.wEName )
                    OR ( mp.wRefRID IS NOT NULL AND @pEName = auth.wEName ))
                AND ( @pEnglishPinyin IS NULL OR ptd.wPersonRID IS NOT NULL)
                AND ( @pIDNo IS NULL OR ptd.wPersonRID IS NOT NULL )
                AND ( @pRole IS NULL OR @pRole = mp.wRole )
                AND ( @pStatus IS NULL OR @pStatus = mp.wStatus )
        ),
        tAgentPerson AS (
            SELECT
                RowID = -1 ,
                wIsAuth = 'Y' ,
                wAgentCodeIn = auth1.wUpLvlAgentCodeIn ,
                wAgentCodeIn_I = auth1.wAgentCodeIn ,
                wCName = auth1.wCName ,
                wEName = auth1.wEName ,
                wNickname = auth1.wNickName,
                wRole = 'CLNT' ,
                wSpeakLangCd = '',
                wWritenLangCd = '',
                wGender = auth1.wSex  ,
                wBirthdate = auth1.wBirthDate ,
                wNationality = auth1.wNationality ,
                wProvince = auth1.wProvince ,
                wAddress = auth1.wAddress  ,
                wTelBusiness = '' ,
                wTelHome = ''  ,
                wTelOther = '' ,
                wRefRID = auth1.RowID ,
                auth1.wStatus ,
                wCrtDt = auth1.wCreateDate ,
                wCrtBy = auth1.wCrtby ,
                wUpdDt = auth1.wUpdDt  ,
                wUpdBy = auth1.wUpdBy,
                wQuantityOfTravelDoc = 0 ,
                wEnglishPinyinInDoc = '' ,
                wIDTypeInDoc = auth1.wIDType ,
                wIDNoInDoc = auth1.wIDNo ,
                wIssueAtInDoc = '' ,
                wExpiryDateInDoc = '' ,
                wRefRIDInDoc = 'N' 
            FROM RollsMary.dbo.mAgent auth1
            LEFT JOIN dbo.mPerson mp1 ON auth1.RowID = mp1.wRefRID
            WHERE auth1.wType = 'AUTH'
                AND auth1.wAuthIdentity IN ( 'AUTH'/*授權人*/, 'BOSS'/*幕後老闆*/, 'OWNER'/*戶主*/, 'DIRECTOR'/*總監*/, 'STAFF'/*伙記*/, 'PARTNER' /*拍檔*/ )
                AND mp1.RowID IS NULL
                AND mp1.wStatus = 'A'
                AND ( @pAgentCodeIn IS NULL OR @pAgentCodeIn = auth1.wAgentCodeIn )
                AND ( @pCName IS NULL OR @pCName = auth1.wCName )
                AND ( @pEName IS NULL OR @pEName = auth1.wEName )
                AND ( @pIDNo IS NULL OR @pIDNo = auth1.wIDNo )
                AND ( @pRole IS NULL OR @pRole = 'CLNT' )
        ),
        tResult AS (
            SELECT
                wSeqNo = ROW_NUMBER() OVER ( ORDER BY mp.wAgentCodeIn DESC, mp.RowID DESC ) ,
                mp.RowID ,
                mp.wIsAuth ,
                mp.wAgentCodeIn ,
                wAgentCode_DisplayInPerson = cstmr.wAgentCode_Display ,
                mp.wCName ,
                mp.wEName ,
                mp.wNickname ,
                mp.wRole ,
                mp.wSpeakLangCd ,
                mp.wWritenLangCd ,
                mp.wGender ,
                mp.wBirthdate ,
                mp.wNationality ,
                mp.wProvince ,
                mp.wAddress ,
                mp.wTelBusiness ,
                mp.wTelHome ,
                mp.wTelOther ,
                mp.wRefRID ,
                mp.wStatus ,
                mp.wCrtDt ,
                mp.wCrtBy ,
                mp.wUpdDt ,
                mp.wUpdBy,
                mp.wQuantityOfTravelDoc,
                mp.wEnglishPinyinInDoc ,
                mp.wIDTypeInDoc ,
                mp.wIDNoInDoc ,
                mp.wIssueAtInDoc ,
                mp.wExpiryDateInDoc ,
                mp.wRefRIDInDoc
            FROM ( SELECT * FROM tPerson UNION SELECT * FROM tAgentPerson ) AS mp
            INNER JOIN RollsMary.dbo.mAgent cstmr ON cstmr.wAgentCodeIn = mp.wAgentCodeIn_I
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT
            tResult.* ,
            wRecordCount
        INTO #tResult
        FROM tResult , tCount
        ORDER BY tResult.wSeqNo
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION ( RECOMPILE );

        WITH tPersonTravelDoc AS (
            SELECT
                rptd.wPersonRID,
                wTravelDocQuantity = COUNT(1),
                wEnglishPinyin =  STUFF(
                        (SELECT CONCAT(', ', sptd.wEnglishPinyin)
                         FROM dbo.mPersonTravelDoc AS sptd
                         WHERE sptd.wPersonRID = rptd.wPersonRID
                            AND NULLIF(sptd.wEnglishPinyin, '') IS NOT NULL
                         FOR XML PATH('')), 1, 2, N'') ,
                wIDType = STUFF(
                        (SELECT CONCAT(',', sptd.wIDType)
                         FROM dbo.mPersonTravelDoc AS sptd
                         WHERE sptd.wPersonRID = rptd.wPersonRID
                            AND NULLIF(sptd.wIDType, '') IS NOT NULL
                         FOR XML PATH('') ), 1, 1, N''),
                wIDNo = STUFF(
                        (SELECT CONCAT(', ', sptd.wIDNo)
                         FROM dbo.mPersonTravelDoc AS sptd
                         WHERE sptd.wPersonRID = rptd.wPersonRID
                            AND NULLIF(sptd.wIDNo, '') IS NOT NULL
                         FOR XML PATH('')), 1, 2, N''),
                wIssueAt = STUFF(
                        (SELECT CONCAT(',', sptd.wIssueAt)
                         FROM dbo.mPersonTravelDoc AS sptd
                         WHERE sptd.wPersonRID = rptd.wPersonRID
                            AND NULLIF(sptd.wIssueAt, '') IS NOT NULL
                         FOR XML PATH('')), 1, 1, N''),
                wExpiryDate = STUFF(
                        (SELECT CONCAT(', ', FORMAT(sptd.wExpiryDate, 'yyyy-MM-dd'))
                         FROM dbo.mPersonTravelDoc sptd
                         WHERE sptd.wPersonRID = rptd.wPersonRID
                            AND sptd.wExpiryDate IS NOT NULL
                         FOR XML PATH('') ), 1, 2, N'') ,
                wHasDoc = STUFF(
                        (SELECT CONCAT(', ', IIF( doc.RowID IS NOT NULL, 'Y', 'N'))
                        FROM dbo.mPersonTravelDoc AS sptd
                        LEFT JOIN CRM_Doc.dbo.eDocument AS doc ON doc.wRefRID = sptd.ROWID
                        WHERE sptd.wPersonRID = rptd.wPersonRID
                        FOR XML PATH('')), 1, 2, '')
            FROM dbo.mPersonTravelDoc AS rptd
            GROUP BY rptd.wPersonRID
        )


        SELECT
            mp.*,
            wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
            wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END,
            wQuantityOfTravelDoc = ISNULL(ptd.wTravelDocQuantity, mp.wQuantityOfTravelDoc),
            wEnglishPinyinInDoc = ISNULL(ptd.wEnglishPinyin, mp.wEnglishPinyinInDoc),
            wIDTypeInDoc = ISNULL(ptd.wIDType, mp.wIDTypeInDoc),
            wIDNoInDoc = ISNULL(ptd.wIDNo, mp.wIDNoInDoc),
            wIssueAtInDoc = ISNULL(ptd.wIssueAt, mp.wIssueAtInDoc) ,
            wExpiryDateInDoc = ISNULL(ptd.wExpiryDate, mp.wExpiryDateInDoc),
            wRefRIDInDoc = ISNULL(ptd.wHasDoc, mp.wRefRIDInDoc)
        FROM #tResult AS mp
        LEFT JOIN tPersonTravelDoc AS ptd ON ptd.wPersonRID = mp.RowID
        LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = mp.wUpdBy
        LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = mp.wCrtBy
        OPTION(RECOMPILE);

        IF OBJECT_ID('tempdb..#tResult') IS NOT NULL BEGIN
		    DROP TABLE #tResult;
	    END
    END