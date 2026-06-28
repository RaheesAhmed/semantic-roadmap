CREATE PROCEDURE [spq].[GetCorpEventGuestLst]
    @pCorpEventRid BIGINT ,
    @pAgentCodeIn VARCHAR(14) ,
    @pLangCd VARCHAR(30) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
/* Test Call
EXEC spq.GetCorpEventGuestLst 1, '1000010180', 'en-GB', 9999, 1
*/
        SET NOCOUNT ON;
        SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        WITH    tResult
                  AS ( SELECT
			-- PRINT [dbo].[fnGetAllFieldNameInTable]('eCorpEventGuest', 'ceg', 'N', '', '', '')
                                ceg.RowID ,
                                ceg.wCorpEventRid ,
                                ceg.wAgentCodeIn ,
                                ceg.wGuestName ,
                                ceg.wPersonRid ,
                                ceg.wGuestInvited ,
                                ceg.wGuestAttend ,
								ceg.wCfmGuestAttend,
                                ceg.wRemark ,
                                ceg.wStatus ,
                                ceg.wCrtDt ,
                                ceg.wUpdDt ,
                                CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByCName ,
                                CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByCName
                       FROM     dbo.eCorpEventGuest ceg
                                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ceg.wUpdBy
                                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ceg.wCrtBy
                       WHERE    ceg.wCorpEventRid = @pCorpEventRid
                                AND ceg.wAgentCodeIn = @pAgentCodeIn
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