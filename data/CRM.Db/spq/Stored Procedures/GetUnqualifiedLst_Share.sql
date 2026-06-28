

CREATE PROCEDURE [spq].[GetUnqualifiedLst_Share]
    @pDeptCd VARCHAR(30) ,
    @pUnqualifiedType VARCHAR(30) ,
    @pReason VARCHAR(30) ,
	@pUnqualifiedStatus VARCHAR(30),
    @pFromDate DATE ,
    @pToDate DATE ,
    @pLangCd VARCHAR(30) ,
    @pStatus CHAR(1) ,
    @pPageSize INT = 999 ,
    @pPageNum INT = 1
AS
    BEGIN
        SET NOCOUNT ON;	

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

        SET @pFromDate = ISNULL(@pFromDate, CAST('1900-01-01' AS DATETIME2));
        SET @pToDate = ISNULL(@pToDate, CAST('2099-12-31' AS DATETIME2));    					            
	
        WITH    cteData
                  AS ( SELECT   uq.RowID ,
                                uq.wAgentCodeIn ,
								uq.wBookingRid ,
								uq.wBookingType ,
                                uq.wDeptCd ,
                                uq.wCompNo ,
                                uq.wUnqualifiedType ,
                                uq.wUnqualifiedStatus ,
                                uq.wReason ,
                                uq.wDetails ,
                                uq.wFollowUpDetails ,
                                ag.wAgentCode_Display ,
                                l_uqt.wTitle AS wPointsTypeName ,
                                l_uqr.wTitle AS wTradingTypeName ,
                                l_uqs.wTitle AS wTradingStatusName ,
                                uq.wCrtDt ,
                                uq.wCrtBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName
                                     ELSE u_cb.wCName
                                END AS wCrtByCName ,
                                uq.wUpdDt ,
                                uq.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                                     ELSE u.wCName
                                END AS wUpdByName
                       FROM     dbo.eUnqualified uq
                                LEFT JOIN RollsMary.dbo.mAgent ag ON uq.wAgentCodeIn = ag.wAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = uq.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = uq.wCrtBy
                                LEFT JOIN CRM.dbo.mLookUp l_uqt ON l_uqt.wCode = uq.wUnqualifiedType
                                                              AND l_uqt.wType = 'UNQUALIFIED_TYPE'
                                                              AND l_uqt.wLangCd = @pLangCd
                                LEFT JOIN CRM.dbo.mLookUp l_uqr ON l_uqr.wCode = uq.wReason
                                                              AND l_uqr.wType = 'UNQUALIFIED_REASON'
                                                              AND l_uqr.wLangCd = @pLangCd
                                LEFT JOIN CRM.dbo.mLookUp l_uqs ON l_uqs.wCode = uq.wUnqualifiedStatus
                                                              AND l_uqs.wType = 'UNQUALIFIED_STATUS'
                                                              AND l_uqs.wLangCd = @pLangCd
                       WHERE    ( @pDeptCd = ''
                                  OR uq.wDeptCd = @pDeptCd
                                )
                                AND ( @pUnqualifiedType = ''
                                      OR uq.wUnqualifiedType = @pUnqualifiedType
                                    )
                                AND ( @pReason = ''
                                      OR uq.wReason = @pReason
                                    )
								 AND ( @pUnqualifiedStatus = ''
                                      OR uq.wUnqualifiedStatus = @pUnqualifiedStatus
                                    )
                                AND uq.wCrtDt >= @pFromDate
                                AND ( uq.wCrtDt < DATEADD(DAY, 1, @pToDate) )
                                AND uq.wStatus = @pStatus
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