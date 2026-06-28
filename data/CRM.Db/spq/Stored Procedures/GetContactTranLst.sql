
CREATE PROCEDURE [spq].[GetContactTranLst]
    @pDeptCd VARCHAR(15),
    @pCategoryCd	VARCHAR(30),
    @pContactStatus VARCHAR(30),
    @pFromDt DATE,
    @pToDt DATE,
    @pUpdBy NVARCHAR(50),
    @pAgentCodeIn VARCHAR(14),
    @pUsrRid BIGINT,
    @pLangCd VARCHAR(30),
    @pPageSize INT = 999,
    @pPageNum INT = 1
AS
    BEGIN
        SET NOCOUNT ON;	

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
        
        SET @pDeptCd = NULLIF(@pDeptCd, '');
        SET @pCategoryCd = NULLIF(@pCategoryCd, '');
        SET @pContactStatus = NULLIF(@pContactStatus, '');
        SET @pFromDt = ISNULL(@pFromDt, '0001-01-01');
        SET @pToDt = ISNULL(@pToDt, '9999-12-31');
        SET @pLangCd = ISNULL(NULLIF(@pLangCd, ''), 'zh-TW');
        SET @pPageSize = ISNULL(IIF(@pPageSize <= 0, NULL, @pPageSize), 100);
        SET @pPageNum = ISNULL(IIF(@pPageNum <= 0, NULL, @pPageNum), 1);
        SET @pUpdBy = NULLIF(@pUpdBy, '');  
        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pUsrRid = ISNULL(@pUsrRid,0);
		
        WITH  tmp AS(
            SELECT 
                 RowID,B.StrColumn,wTitle
            FROM
            (
                  SELECT  StrXml = CONVERT(xml,'<root><v>' + REPLACE(wCategoryCd, ',', '</v><v>') + '</v></root>'),RowID,wRefNo
                  FROM dbo.eContactTran
            )A
            OUTER APPLY
            (
                  SELECT StrColumn = N.v.value('.', 'nvarchar(40)'),l.wTitle
                  FROM A.StrXml.nodes('/root/v') N(v)
                  LEFT JOIN dbo.mLookUp l ON l.wCode = N.v.value('.', 'nvarchar(40)') AND wType = 'CONTACT_CATEGORY' AND wLangCd= @pLangCd
            )B
        ),
        tCategoryName AS(
            SELECT ct.RowID,STUFF((SELECT ','+wTitle FROM tmp WHERE tmp.RowID = ct.RowID FOR XML PATH('')),1,1,'') AS wCategoryName
            FROM dbo.eContactTran ct
        ),
        tResult AS (
            SELECT
                ct.RowID,
                ct.wRefNo,
                ct.wContactTypeName,
                ct.wDateFrom,
                ct.wDateTo,
                ct.wLocation,
                ct.wCategoryCd,
                ct.wSubCategoryCd,
                ct.wContactStatus,
                ct.wUpdDt,
                ct.wUpdBy,
                wUpdByName = CASE WHEN @pLangCd = 'en-GB' THEN u.wName ELSE u.wCName END,
                ct.wRemark,
                ct.wDeptCd,
                tc.wCategoryName
            FROM dbo.eContactTran ct
            LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = ct.wUpdBy
            LEFT JOIN tCategoryName tc ON tc.RowID = ct.RowID
            WHERE  ct.wStatus = 'A'
                AND ( @pDeptCd IS NULL OR ct.wDeptCd = @pDeptCd )
                AND ( @pUpdBy IS NULL OR  (u.wCName like '%'+ @pUpdBy + '%') OR (u.wName like '%'+ @pUpdBy + '%') OR ( u.wUsrId like '%'+ @pUpdBy + '%'))
                AND ( @pAgentCodeIn IS NULL OR @pAgentCodeIn IN(SELECT ctp.wAgentCodeIn FROM dbo.eContactTranParticipant ctp WHERE ctp.wContactTranRid = ct.RowID))
                AND ( @pContactStatus IS NULL OR ct.wContactStatus = @pContactStatus )
                AND (@pCategoryCd IS NULL OR ct.wCategoryCd like '%' +@pCategoryCd+ '%')
                AND NOT (( CAST(ct.wDateFrom AS DATE) < @pFromDt AND CAST(ct.wDateTo AS DATE) < @pFromDt )
                    OR ( CAST(ct.wDateFrom AS DATE) > @pToDt AND CAST(ct.wDateTo AS DATE) > @pToDt)
                )
                AND ( @pUsrRid = 0 OR @pUsrRid IN(SELECT wUsrRid FROM dbo.eContactTranUsr ctu WHERE ctu.wContactTranRid = ct.RowID))
        ),
        tCount AS (
            SELECT wRecordCount = COUNT(1)
            FROM tResult
        )

        SELECT
            *
        FROM tResult, tCount
        ORDER BY wUpdDt DESC
        OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
        FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );
    END;