
CREATE PROCEDURE [spq].[GetAdviceLst]
    @pAdviceStatus VARCHAR(20) ,
    @pType VARCHAR(20) ,
    @pDeptCd VARCHAR(15) ,
    @pFromDate DATE ,
    @pToDate DATE ,
    @pLangCd VARCHAR(30) ,
    @pStatus CHAR(1) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
        SET NOCOUNT ON;	

        SET @pFromDate = ISNULL(@pFromDate, CAST('1900-01-01' AS DATE));        
        SET @pToDate = CASE WHEN @pToDate IS NULL
                            THEN CAST('2099-12-31' AS DATE)
                            ELSE CAST(DATEADD(dd, 1, @pToDate) AS DATE)
                       END;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
		
        WITH    cteData
                  AS ( SELECT   a.RowID ,
                                a.wRefNo ,
                                a.wAim ,
                                a.wDate ,
                                a.wAgentCodeIn ,
                                ag.wAgentCode_Display ,
                                a.wType ,
                                a.wSubType ,
                                a.wIsHighPriority ,
                                a.wReceivedBy ,
                                a.wReceivedDeptCd ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_rb.wName
                                     ELSE u_rb.wCName
                                END AS wReceivedByCName ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_fb.wName
                                     ELSE u_fb.wCName
                                END AS wLatestFollowUpByCName ,
                                tss.wLatestFollowUpBy ,
                                tss.wLatestFollowUpDt ,
                                a.wAdviceStatus ,
                                a.wContent ,
                                a.wStatus ,
                                a.wCrtDt ,
                                a.wCrtBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName
                                     ELSE u_cb.wCName
                                END AS wLatestCreatedByCName ,
                                a.wUpdDt ,
                                a.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                                     ELSE u.wCName
                                END AS wUpdByName
                       FROM     dbo.eAdvice a
                                LEFT JOIN RollsMary.dbo.mAgent ag ON a.wAgentCodeIn = ag.wAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = a.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_rb ON u_rb.RowID = a.wReceivedBy
                                LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = a.wCrtBy
                                LEFT JOIN CRM.dbo.eTaskSheetSummary tss ON tss.wRelatedRid = a.RowID
                                                              AND tss.wRelatedType = 'eAdvice'
                                LEFT JOIN RollsMary.dbo.mUsr u_fb ON u_fb.RowID = tss.wLatestFollowUpBy
                       WHERE    ( @pDeptCd = ''
                                  OR a.wReceivedDeptCd = @pDeptCd
                                )
                                AND ( @pAdviceStatus = ''
                                      OR a.wAdviceStatus = @pAdviceStatus
                                    )
                                AND ( a.wDate >= @pFromDate )
                                AND ( a.wDate < @pToDate
                                      AND a.wStatus = @pStatus
                                    )
                                AND ( @pType = ''
                                      OR a.wType = @pType
                                    )
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