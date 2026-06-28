
CREATE PROCEDURE [spq].[GetPerson_Master]
(
    @pAgentCodeIn VARCHAR(14) ,
    @pAgentCode VARCHAR(15) = '',
    @pCName NVARCHAR(50) ,
    @pRole VARCHAR(10) ,
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(10) = 'en-GB' ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
)
AS
    BEGIN
        SET NOCOUNT ON;    

        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pCName = NULLIF(@pCName, '');
        SET @pRole = NULLIF(@pRole, '');
        SET @pStatus = NULLIF(@pStatus, '');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 999);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'en-GB');
        SET @pAgentCode = NULLIF(@pAgentCode, '');

        WITH tUsr AS (
            SELECT RowID, wName = CASE WHEN @pLangCd = 'en-gb' THEN wName ELSE wCName END FROM RollsMary.dbo.mUsr
        ),
        tResult AS (
            SELECT
                wSeqNo = ROW_NUMBER() OVER ( ORDER BY mp.RowID ) ,
                mp.RowID ,
                mp.wAgentCodeIn ,
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
                mp.wStatus ,
                mp.wCrtDt ,
                mp.wCrtBy ,
                mp.wUpdDt ,
                mp.wUpdBy ,
                wUpdByCName = usr.wName,
                wCreatedByCName = crusr.wName,
                wTitle = cstmr.wAgentCode_Display
            FROM dbo.mPerson AS mp
            INNER JOIN RollsMary.dbo.mAgent cstmr ON cstmr.wAgentCodeIn = mp.wAgentCodeIn
            LEFT JOIN tUsr AS usr ON usr.RowID = mp.wUpdBy
            LEFT JOIN tUsr AS crusr ON crusr.RowID = mp.wCrtBy
            WHERE ( @pAgentCodeIn IS NULL OR @pAgentCodeIn = mp.wAgentCodeIn )
                AND ( @pCName IS NULL OR @pCName = mp.wCName )
                AND ( @pRole IS NULL OR @pRole = mp.wRole )
                AND ( @pStatus IS NULL OR @pStatus = mp.wStatus )
                AND ( @pAgentCode IS NULL OR @pAgentCode = cstmr.wAgentCode )
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1) FROM tResult
        )

        SELECT
            tResult.* ,
            wRecordCount
        FROM tResult , tCount
        ORDER BY RowID DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS    
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION (RECOMPILE);
    END;