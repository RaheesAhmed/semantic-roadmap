
CREATE PROCEDURE [spq].[GetPointsTradingLst]
    @pAgentCodeIn VARCHAR(14) ,
    @pTradingStatus VARCHAR(30) ,
    @pTradingType VARCHAR(30) ,
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
                  AS ( SELECT   pt.RowID ,
                                pt.wRequestDt ,
                                pt.wTargetExpiryDate ,
                                pt.wTargetAmt ,
                                pt.wTargetDiscountRatio ,
                                pt.wAmtDone ,
                                pt.wAgentCodeIn ,
                                ag.wAgentCode_Display ,
                                pt.wPointsType ,
                                l_ps.wTitle AS wPointsTypeName ,
                                pt.wTradingType ,
                                l_ptt.wTitle AS wTradingTypeName ,
                                pt.wTradingStatus ,
                                l_pts.wTitle AS wTradingStatusName ,
                                pt.wCrtDt ,
                                pt.wCrtBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_cb.wName
                                     ELSE u_cb.wCName
                                END AS wCrtByCName ,
                                pt.wUpdDt ,
                                pt.wUpdBy ,
                                CASE WHEN @pLangCd = 'en-GB' THEN u.wName
                                     ELSE u.wCName
                                END AS wUpdByName,
                                wOutstandAmt=pt.wTargetAmt-pt.wAmtDone,
                                CASE WHEN @pLangCd = 'en-GB' THEN u_staff.wName
                                     ELSE u_staff.wCName
                                END AS wFollowStaffName 
                       FROM     dbo.ePointsTrading pt
                                LEFT JOIN RollsMary.dbo.mAgent ag ON pt.wAgentCodeIn = ag.wAgentCodeIn
                                LEFT JOIN RollsMary.dbo.mUsr u ON u.RowID = pt.wUpdBy
                                LEFT JOIN RollsMary.dbo.mUsr u_cb ON u_cb.RowID = pt.wCrtBy
                                LEFT JOIN RollsMary.dbo.mUsr u_staff ON u_staff.RowID = pt.wFollowStaffRid
                                LEFT JOIN CRM.dbo.mLookUp l_ptt ON l_ptt.wCode = pt.wTradingType
                                                              AND l_ptt.wType = 'POINTS_TRADING_TYPE'
                                                              AND l_ptt.wLangCd = @pLangCd
                                LEFT JOIN CRM.dbo.mLookUp l_ps ON l_ps.wCode = pt.wPointsType
                                                              AND l_ps.wType = 'POINTS_TYPE'
                                                              AND l_ps.wLangCd = @pLangCd
                                LEFT JOIN CRM.dbo.mLookUp l_pts ON l_pts.wCode = pt.wTradingStatus
                                                              AND l_pts.wType = 'POINTS_TRADING_STATUS'
                                                              AND l_pts.wLangCd = @pLangCd
                       WHERE    ( @pAgentCodeIn = ''
                                  OR pt.wAgentCodeIn = @pAgentCodeIn
                                )
                                AND ( @pTradingStatus = '' OR @pTradingStatus IS NULL
                                      OR pt.wTradingStatus = @pTradingStatus
                                    )
                                AND (
                                      @pTradingType = '' OR @pTradingType IS NULL
                                      OR pt.wTradingType = @pTradingType     
                                     )
                                AND pt.wRequestDt >= @pFromDate
                                AND ( pt.wRequestDt < DATEADD(DAY, 1, @pToDate) )
                                AND pt.wStatus = @pStatus
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
	---FETCH NEXT @pPageSize ROWS ONLY
        --OPTION  ( RECOMPILE );

    END;