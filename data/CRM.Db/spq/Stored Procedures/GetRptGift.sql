
CREATE PROCEDURE [spq].[GetRptGift]
    @pAgentCodeIn VARCHAR(14) ,
    @pDateFrom DATETIME2,
    @pDateTo DATETIME2,
    @pReqCounterRid BIGINT ,
    @pType VARCHAR(30) ,
    @pDeptCd VARCHAR(30) ,
    @pReasonCd VARCHAR(30) ,
    @pIsReceived CHAR(1) ,
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(30) 

AS
    BEGIN
        SET NOCOUNT ON;

        SET @pAgentCodeIn = NULLIF(@pAgentCodeIn, '');
        SET @pDateFrom = ISNULL(@pDateFrom, '0001-01-01');
        SET @pDateTo = ISNULL(@pDateTo, '9999-12-31');
        SET @pLangCd = ISNULL(@pLangCd, 'zh-TW');
        SET @pType = NULLIF(@pType, '');
        SET @pDeptCd = NULLIF(@pDeptCd, '');
        SET @pReasonCd = NULLIF(@pReasonCd, '');
        SET @pStatus = NULLIF(@pStatus, ' ');
        SET @pIsReceived = NULLIF(@pIsReceived, ' ');
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	
        WITH    cteData
                  AS ( SELECT 
                                g_t.RowID ,
                                wDebitCounterName = dsc.wName ,
                                g_t.wDate ,
                                a.wAgentCode_Display ,
                                wReqDeptName=CASE WHEN @pLangCd = 'en-GB' THEN depart.wEName ELSE depart.wCName END ,
                                wStaffName = CASE WHEN @pLangCd = 'en-GB' THEN uStaff.wName
                                                  ELSE uStaff.wCName
                                             END ,
                                CASE WHEN wRefTableName = 'eStockSales' THEN CASE WHEN @pLangCd = 'en-GB' THEN a_ss.wEName
                                                                                  ELSE a_ss.wCName
                                                                             END
                                     WHEN g_t.wRefTableName = 'eBooking' THEN CASE WHEN @pLangCd = 'en-GB' THEN a_booking_recipient.wEName
                                                                                   ELSE a_booking_recipient.wCName
                                                                              END
                                     ELSE g_t.wRecipient
                                END AS wRecipient ,
                                sl.wTitle AS wTypeName,
                                sul.wTitle AS wSubTypeName,
                                g_t.wCurrCode ,
                                g_t.wAmount ,
                                g_t.wCost,
                                l.wTitle AS wReasonName,
                                wEventCodeName = CASE WHEN @pLangCd = 'en-GB' THEN mec.wEName ELSE mec.wCName END ,
                                g_t.wIsReceived ,
                                wStatus =st.wTitle,
                                g_t.wRemark ,
                                g_t.wUpdDt ,
                                CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByName 
                       FROM dbo.eGift g_t
                       LEFT JOIN dbo.eStockSales ss ON ss.RowID = g_t.wRefTableRid AND g_t.wRefTableName = 'eStockSales'
                       LEFT JOIN dbo.eBooking b ON b.RowID = g_t.wRefTableRid AND g_t.wRefTableName = 'eBooking'
                       LEFT JOIN RollsMary.dbo.mAgent a ON g_t.wReqAgentCodeIn = a.wAgentCodeIn
                       LEFT JOIN RollsMary.dbo.mAgent a_ss ON ss.wDebitAgentCodeIn = a_ss.wAgentCodeIn
                       LEFT JOIN RollsMary.dbo.mAgent a_booking_recipient ON a_booking_recipient.wAgentCodeIn = b.wApprovalAgentCodeIn
                       LEFT JOIN dbo.mServiceCounter dsc ON dsc.RowID = g_t.wDebitCounterRid
                       LEFT JOIN [RollsMary].[dbo].[mUsr] uStaff ON uStaff.RowID = g_t.wReqStaffRid
                       LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = g_t.wUpdBy
                       LEFT JOIN dbo.mEventCode  mec ON g_t.wEventCodeRid=mec.RowID
                       LEFT JOIN dbo.mLookUp l ON g_t.wReasonCd=l.wCode AND l.wType='GIFT_REASON' AND l.wLangCd=@pLangCd
                       LEFT JOIN dbo.mLookUp sl ON g_t.wType=sl.wCode AND sl.wType='GIFT_TYPE' AND sl.wLangCd=@pLangCd
                       LEFT JOIN dbo.mLookUp sul ON g_t.wSubType=sul.wCode AND sul.wType='GIFT_SUB_TYPE' AND sul.wLangCd=@pLangCd
                       LEFT JOIN RollsMary.dbo.mDepartment depart ON depart.wCode=g_t.wReqDeptCd AND depart.wIsRealDept='Y' AND NULLIF(depart.wUserLineGrp,'') IS NULL
                       LEFT JOIN dbo.mLookUp st ON g_t.wStatus=st.wCode AND st.wType='COMMON_STATUS' AND st.wLangCd=@pLangCd
                       WHERE    ( @pStatus IS NULL OR g_t.wStatus = @pStatus )
                                AND ( @pAgentCodeIn IS NULL OR g_t.wReqAgentCodeIn = @pAgentCodeIn )
                                AND (  g_t.wDate BETWEEN @pDateFrom AND @pDateTo)
                                AND ( @pReqCounterRid = 0 OR g_t.wDebitCounterRid = @pReqCounterRid )
                                AND ( @pType IS NULL OR g_t.wType = @pType )
                                AND ( @pDeptCd IS NULL  OR g_t.wReqDeptCd = @pDeptCd )
                                AND ( @pReasonCd IS NULL  OR g_t.wReasonCd = @pReasonCd )
                                AND ( @pIsReceived IS NULL  OR g_t.wIsReceived = @pIsReceived )
                     )

            SELECT  d.* 
            FROM    cteData d 
            ORDER BY d.wUpdDt DESC;
                  
    END;