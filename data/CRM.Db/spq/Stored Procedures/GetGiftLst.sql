
CREATE PROCEDURE [spq].[GetGiftLst]
    @pAgentCodeIn VARCHAR(14) ,
    @pDateFrom DATETIME2,
    @pDateTo DATETIME2,
    @pReqCounterRid BIGINT ,
    @pType VARCHAR(30) ,
    @pDeptCd VARCHAR(30) ,
    @pReasonCd VARCHAR(30) ,
    @pIsReceived CHAR(1) ,
    @pStatus CHAR(1) ,
    @pLangCd VARCHAR(30) ,
    @pPageNum INT = 1 ,
    @pPageSize INT = 999
/*
-- Test Call
EXEC [spq].[GetGiftLst] @pAgentCodeIn = '', @pDate = '0001-01-01', @pCompNo = 10, @pType = NULL, @pDeptCd = '', @pStatus = ' ', @pLangCd = 'zh-TW', @pPageNum = 1, @pPageSize = 20;
*/
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pDateFrom = ISNULL(@pDateFrom, '0001-01-01');
        SET @pDateTo = ISNULL(@pDateTo, '9999-12-31');
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
	
        WITH    cteData
                  AS ( SELECT   g_t.RowID ,
                                g_t.wRefBookingRid ,
                                g_t.wRefTableName ,
                                g_t.wRefTableRid ,
                                g_t.wOriActionType ,
                                g_t.wDebitCounterRid,
                                g_t.wReqCounterRid ,
                                wDebitCounterName = dsc.wName ,
                                wReqCounterName = rsc.wName,
                                g_t.wCompNo ,
                                g_t.wCageCodeIn ,
                                g_t.wReqDeptCd ,
                                g_t.wReqStaffRid ,
                                CASE WHEN wRefTableName = 'eStockSales' THEN ss.wDebitAgentCodeIn
                                     WHEN g_t.wRefTableName = 'eBooking' THEN b.wReqAgentCodeIn
                                     ELSE g_t.wReqAgentCodeIn
                                END AS wReqAgentCodeIn ,
                                g_t.wDate ,
                                CASE WHEN wRefTableName = 'eStockSales' THEN CASE WHEN @pLangCd = 'en-GB' THEN a_ss.wEName
                                                                                  ELSE a_ss.wCName
                                                                             END
                                     WHEN g_t.wRefTableName = 'eBooking' THEN CASE WHEN @pLangCd = 'en-GB' THEN a_booking_recipient.wEName
                                                                                   ELSE a_booking_recipient.wCName
                                                                              END
                                     ELSE g_t.wRecipient
                                END AS wRecipient ,
                                g_t.wCurrCode ,
                                g_t.wAmount ,
                                g_t.wType ,
                                g_t.wSubType ,
                                g_t.wReasonCd ,
                                g_t.wIsReceived ,
                                g_t.wRemark ,
                                g_t.wEventCodeRid ,
                                g_t.wStatus ,
                                g_t.wCrtDt ,
                                g_t.wCrtBy ,
                                g_t.wUpdDt ,
                                g_t.wUpdBy ,
                                b.wRefNo AS wBookingRefNo ,
                                ss.wRefNo AS wStockSalesRefNo ,
                                'N' AS RecordState ,
                                a.wAgentCode_Display ,
                                wStaffName = CASE WHEN @pLangCd = 'en-GB' THEN uStaff.wName
                                                  ELSE uStaff.wCName
                                             END ,
                                CASE WHEN @pLangCd = 'en-GB' THEN usr.wName
                                     ELSE usr.wCName
                                END AS wUpdByName ,
                                CASE WHEN @pLangCd = 'en-GB' THEN crusr.wName
                                     ELSE crusr.wCName
                                END AS wCreatedByName,
                                a.wAgentCodeIn,
                                g_t.wCost
                       FROM dbo.eGift g_t
                       LEFT JOIN dbo.eStockSales ss ON ss.RowID = g_t.wRefTableRid AND g_t.wRefTableName = 'eStockSales'
                       LEFT JOIN dbo.eBooking b ON b.RowID = g_t.wRefTableRid AND g_t.wRefTableName = 'eBooking'
                       LEFT JOIN RollsMary.dbo.mAgent a ON g_t.wReqAgentCodeIn = a.wAgentCodeIn
                       LEFT JOIN RollsMary.dbo.mAgent a_ss ON ss.wDebitAgentCodeIn = a_ss.wAgentCodeIn
                       LEFT JOIN RollsMary.dbo.mAgent a_booking_recipient ON a_booking_recipient.wAgentCodeIn = b.wApprovalAgentCodeIn
                       LEFT JOIN dbo.mServiceCounter dsc ON dsc.RowID = g_t.wDebitCounterRid
                       LEFT JOIN dbo.mServiceCounter rsc ON rsc.RowID = g_t.wReqCounterRid
                       LEFT JOIN [RollsMary].[dbo].[mUsr] uStaff ON uStaff.RowID = g_t.wReqStaffRid
                       LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = g_t.wUpdBy
                       LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = g_t.wCrtBy
                       WHERE    ( @pStatus = ' '
                                  OR g_t.wStatus = @pStatus
                                )
                                AND ( @pAgentCodeIn = ''
                                      OR g_t.wReqAgentCodeIn = @pAgentCodeIn
                                    )
                                AND (  g_t.wDate BETWEEN @pDateFrom AND @pDateTo)
                                AND ( @pReqCounterRid = 0
                                      OR g_t.wDebitCounterRid = @pReqCounterRid
                                    )
                                AND ( ISNULL(@pType, '') = ''
                                      OR g_t.wType = @pType
                                    )
                                AND ( @pDeptCd = ''
                                      OR g_t.wReqDeptCd = @pDeptCd
                                    )
                                AND ( @pReasonCd = ''
                                      OR g_t.wReasonCd = @pReasonCd
                                    )
                                AND ( @pIsReceived = ' '
                                      OR g_t.wIsReceived = @pIsReceived
                                    )

						--AND g_t.wStatus = 'A'
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