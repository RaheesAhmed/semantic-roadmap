
CREATE PROCEDURE [spq].[GetContactTranUsrLst]
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
                  AS ( SELECT   ctu.RowID ,
                                ctu.wContactTranRid ,
                                ctu.wUsrRid ,
								CASE WHEN @pLangCd = 'en-GB' THEN u_ctu.wName
                                     ELSE u_ctu.wCName
								END AS wUsrName,
								CASE WHEN @pLangCd = 'en-GB' THEN c.wEName
                                     ELSE c.wCName
								END AS wCompName,
								ctu.wDeptCd,
								lu.wTitle AS wDeptName,
                                ctu.wStatus ,
                                ctu.wCrtDt ,
                                ctu.wCrtBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName
                                     ELSE u_cb.wCName
                                END AS wCrtByName ,
                                ctu.wUpdDt ,
                                ctu.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                                     ELSE u.wCName
                                END AS wUpdByName
                       FROM     dbo.eContactTranUsr ctu
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = ctu.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = ctu.wCrtBy
								LEFT JOIN RollsMary.dbo.mUsr u_ctu ON u_ctu.RowID = ctu.wUsrRid
								LEFT JOIN RollsMary.dbo.mCompany c ON c.wCompNo = u_ctu.wCompNo
								LEFT JOIN CRM.dbo.mLookUp lu ON lu.wType = 'DEPARTMENT' AND lu.wLangCd = @pLangCd
								AND lu.wCode = ctu.wDeptCd
                       WHERE    ctu.wContactTranRid = @pContactTranRid
                                AND ctu.wStatus = @pStatus
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