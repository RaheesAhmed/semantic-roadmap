
CREATE PROCEDURE [spq].[GetPersonAuth_Booking]
(
    @pAgentCodeIn VARCHAR(14) ,
    @pAgentCode VARCHAR(15) = '' ,
    @pCName NVARCHAR(50) ,
    @pRole NCHAR(10) ,
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(30) = 'en-GB' ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
)
AS
    BEGIN
        SET NOCOUNT ON;	
		
        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pAgentCode = NULLIF(@pAgentCode, '');
        SET @pCName = NULLIF(@pCName, '');
        SET @pRole = NULLIF(@pRole, '');
        SET @pStatus = NULLIF(@pStatus, '');
        SET @pLangCd = ISNULL(@pLangCd, 'en-GB');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 9999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);	

        WITH tPersonTravelDoc AS (
            SELECT
                rptd.wPersonRID,
                wTravelDocQuantity = COUNT(1),
                wIDNo = STUFF(
                        (SELECT CONCAT(', ', sptd.wIDNo)
                         FROM dbo.mPersonTravelDoc AS sptd
                         WHERE sptd.wPersonRID = rptd.wPersonRID
                            AND NULLIF(sptd.wIDNo, '') IS NOT NULL
                         FOR XML PATH('')), 1, 2, N'')
            FROM dbo.mPersonTravelDoc AS rptd
            GROUP BY rptd.wPersonRID
        ),
        tPerson AS (
            SELECT
                mp.RowID ,
                wQuantityOfTravelDoc = ptd.wTravelDocQuantity ,
                wIDNo = ptd.wIDNo ,
                wIsAuth = IIF(mp.wRefRID IS NULL, 'N', 'Y' ),
                wAgentCodeIn = IIF( mp.wRefRID IS NULL, mp.wAgentCodeIn, auth.wUpLvlAgentCodeIn ),
                wAgentCodeIn_I = IIF( mp.wRefRID IS NULL, mp.wAgentCodeIn, auth.wAgentCodeIn ),
                wCName = IIF ( mp.wRefRID IS NULL, mp.wCName, auth.wCName ),
                wEName = IIF( mp.wRefRID IS NULL, mp.wEName, auth.wEName ),
                wNickname = IIF ( mp.wRefRID IS NULL, mp.wNickname, auth.wNickName ),
                mp.wRole ,
                mp.wSpeakLangCd ,
                mp.wWritenLangCd ,
                wGender = IIF( mp.wRefRID IS NULL, mp.wGender, auth.wSex ),
                wBirthdate = IIF( mp.wRefRID IS NULL, mp.wBirthdate, auth.wBirthDate ),
                wNationality = IIF( mp.wRefRID IS NULL, mp.wNationality, auth.wNationality ),
                wProvince = IIF( mp.wRefRID IS NULL, mp.wProvince, auth.wProvince ),
                wAddress = IIF( mp.wRefRID IS NULL, mp.wAddress, auth.wAddress ),
                mp.wTelBusiness ,
                mp.wTelHome ,
                mp.wTelOther ,
                mp.wRefRID ,
                mp.wStatus ,
                wCrtDt = IIF( mp.wRefRID IS NULL, mp.wCrtDt, auth.wCreateDate ),
                wCrtBy = IIF( mp.wRefRID IS NULL, mp.wCrtBy, auth.wCrtby ), 
                wUpdDt = IIF( mp.wRefRID IS NULL, mp.wUpdDt, auth.wUpdDt ),
                wUpdBy = IIF( mp.wRefRID IS NULL, mp.wUpdBy, auth.wUpdBy )
            FROM dbo.mPerson AS mp
            LEFT JOIN RollsMary.dbo.mAgent AS auth ON auth.RowID = mp.wRefRID
                                                      AND auth.wType = 'AUTH'
                                                      AND auth.wAuthIdentity IN ( 'AUTH'/*授權人*/, 'BOSS'/*幕後老闆*/, 'OWNER'/*戶主*/, 'DIRECTOR'/*總監*/, 'STAFF'/*伙記*/, 'PARTNER' /*拍檔*/ )
                                                      AND mp.wStatus = 'A'
            LEFT JOIN tPersonTravelDoc AS ptd ON ptd.wPersonRID = mp.RowID
        ),
        tAgentPerson As (
            SELECT
                RowID = -1 ,
                wQuantityOfTravelDoc = 0  ,
                wIDNo = auth1.wIDNo  ,
                wIsAuth = 'Y' ,
                wAgentCodeIn = auth1.wUpLvlAgentCodeIn ,
                wAgentCodeIn_I = auth1.wAgentCodeIn ,
                wCName = auth1.wCName ,
                wEName = auth1.wEName ,
                wNickname = auth1.wNickName ,
                wRole = 'CLNT' ,
                wSpeakLangCd = ''  ,
                wWritenLangCd = ''  ,
                wGender = auth1.wSex ,
                wBirthdate = auth1.wBirthDate ,
                wNationality = auth1.wNationality  ,
                wProvince = auth1.wProvince  ,
                wAddress = auth1.wAddress ,
                wTelBusiness  = '',
                wTelHome = '' ,
                wTelOther = '' ,
                wRefRID = auth1.RowID ,
                auth1.wStatus ,
                wCrtDt = auth1.wCreateDate ,
                wCrtBy = auth1.wCrtby ,
                wUpdDt = auth1.wUpdDt ,
                wUpdBy = auth1.wUpdBy
            FROM RollsMary.dbo.mAgent auth1
            LEFT JOIN dbo.mPerson mp1 ON auth1.RowID = mp1.wRefRID
            WHERE auth1.wType = 'AUTH'
                AND auth1.wAuthIdentity IN ('AUTH'/*授權人*/,
                                            'BOSS'/*幕後老闆*/,
                                            'OWNER'/*戶主*/,
                                            'DIRECTOR'/*總監*/,
                                            'STAFF'/*伙記*/,
                                            'PARTNER' /*拍檔*/)
                AND mp1.RowID IS NULL
                AND mp1.wStatus = 'A'
        ),
        tResult AS (
            SELECT
                wSeqNo = ROW_NUMBER() OVER ( ORDER BY mp.wAgentCodeIn DESC, mp.RowID DESC ) ,
                mp.RowID ,
                mp.wIDNo ,
                mp.wIsAuth ,
                mp.wAgentCodeIn ,
                wTitle = cstmr.wAgentCode_Display ,
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
                mp.wUpdBy ,
                wUpdByCName = CASE WHEN @pLangCd = 'en-gb' THEN usr.wName ELSE usr.wCName END ,
                wCreatedByCName = CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName ELSE crusr.wCName END
            FROM (SELECT * FROM tPerson UNION SELECT * FROM tAgentPerson) AS mp
            LEFT JOIN RollsMary.dbo.mUsr usr ON usr.RowID = mp.wUpdBy
            LEFT JOIN RollsMary.dbo.mUsr crusr ON crusr.RowID = mp.wCrtBy
            INNER JOIN RollsMary.dbo.mAgent cstmr ON ( cstmr.wAgentCodeIn = mp.wAgentCodeIn_I )
            WHERE ( @pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn )
                AND ( @pAgentCode IS NULL OR @pAgentCode = cstmr.wAgentCode )
                AND ( @pCName IS NULL OR @pCName = mp.wCName )
                AND ( @pRole IS NULL OR @pRole = mp.wRole )
                AND ( @pStatus IS NULL OR @pStatus = mp.wStatus )
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )
            
        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY tResult.wSeqNo
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE ); 
    END;