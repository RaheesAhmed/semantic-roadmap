CREATE PROCEDURE [spq].[GetCorpEventAgentLst]
    @pCorpEventRid BIGINT ,
    @pLangCd VARCHAR(30) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
/* Test Call
EXEC spq.GetCorpEventAgentLst 1, 'en-GB', 9999, 1
*/
        SET NOCOUNT ON;
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        WITH    tResult
                  AS ( SELECT
			-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventAgent', 'cea', 'N', '', '', '')
                                cea.RowID ,
                                cea.wCorpEventRid ,
                                cea.wAgentCodeIn ,
                                cea.wResponseType ,
                                cea.wGuestInvited ,
                                cea.wGuestAttend ,
								cea.wCfmGuestAttend,
                                cea.wRemark ,
                                cea.wStatus ,
                                cea.wCrtDt ,
                                cea.wUpdDt ,
                                a.wAgentCode_Display ,
                                a.wCName ,
                                CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     dbo.eCorpEventAgent cea
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = cea.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = cea.wCrtBy
                                LEFT JOIN [RollsMary].[dbo].[mAgent] a ON cea.wAgentCodeIn = a.wAgentCodeIn
                       WHERE    cea.wCorpEventRid = @pCorpEventRid
                     ),
                tCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     tResult
                     )
            SELECT  tResult.* ,
                    wRecordCount
            FROM    tResult ,
                    tCount
            ORDER BY tResult.RowID
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY;


    END;