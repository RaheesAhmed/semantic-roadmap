
CREATE PROCEDURE [spq].[GetContactTranParticipantLst]
    @pContactTranRid BIGINT ,
    @pLangCd VARCHAR(30) ,
    @pStatus CHAR(1) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
        SET NOCOUNT ON;	
    
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        WITH    cteData
                  AS ( SELECT   ctp.RowID ,
                                ctp.wContactTranRid ,
                                ctp.wAgentCodeIn,
								a.wAgentCode_Display,
								CASE WHEN @pLangCd = 'en-GB' THEN a.wEName
                                     ELSE a.wCName
								END AS wAgentName,
                                ctp.wParticipated ,
                                ctp.wStatus ,
                                ctp.wCrtDt ,
                                ctp.wCrtBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName
                                     ELSE u_cb.wCName
                                END AS wCrtByName ,
                                ctp.wUpdDt ,
                                ctp.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                                     ELSE u.wCName
                                END AS wUpdByName
                       FROM     dbo.eContactTranParticipant ctp
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = ctp.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = ctp.wCrtBy
								LEFT JOIN RollsMary.dbo.mAgent a ON a.wAgentCodeIn = ctp.wAgentCodeIn
                       WHERE    ctp.wContactTranRid = @pContactTranRid
                                AND ctp.wStatus = @pStatus
                     ),
                cteCount
                  AS ( SELECT   wRecordCount = COUNT(*)
                       FROM     cteData
                     )
            SELECT  d.* ,
                    c.wRecordCount
            FROM    cteData d ,
                    cteCount c
            ORDER BY d.wUpdDt DESC
                    OFFSET @pPageSize * ( @pPageNum - 1 ) ROWS
	FETCH NEXT @pPageSize ROWS ONLY
        OPTION  ( RECOMPILE );

    END;