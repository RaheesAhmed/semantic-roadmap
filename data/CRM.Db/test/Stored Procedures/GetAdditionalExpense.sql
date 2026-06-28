CREATE PROCEDURE [test].[GetAdditionalExpense]
    (
      @pBookingRid BIGINT ,
      @pLangCd VARCHAR(10)
    )
AS
    BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
        SET @pBookingRid = ISNULL(@pBookingRid, 0);
        SET @pLangCd = LOWER(ISNULL(@pLangCd, 'en-gb'));

        SET NOCOUNT ON;
	
    -- Insert statements for procedure here

        SELECT
      --CASE WHEN b.wBookingType = 'HELI' THEN	'H' + CAST(h.wTicketId AS VARCHAR) WHEN b.wBookingType = 'AIRTICKET' THEN 'A' + CAST(a.wClientTicketId AS VARCHAR) WHEN b.wBookingType = 'ADDITIONALEXPENSES' THEN CAST(ae.RowID AS VARCHAR) END AS wBookingNo,
                CASE WHEN b.wBookingType = 'HELI'
                     THEN 'H' + CAST(h.wTicketId AS VARCHAR)
                     WHEN b.wBookingType = 'AIRTICKET'
                     THEN 'A' + CAST(a.RowID AS VARCHAR)
                     WHEN ae.wBookingRefRid <= 0 AND eb.wBookingType = 'ADDITIONALEXPENSES'
                     THEN CAST(ae.RowID AS VARCHAR)
                END AS wBookingNo ,
                CASE WHEN ae.wBookingRefRid <= 0 THEN eb.wDebitDt
                     ELSE b.wDebitDt
                END AS wDebitDt ,
                sc.wName AS wDebitServiceCounter ,
                CASE WHEN ae.wBookingRefRid <= 0 THEN eb.wDebitCounterRid
                     ELSE b.wDebitCounterRid
                END AS wDebitCounterRid ,
                daAgent.wAgentCode_Display ,
                CASE WHEN ae.wBookingRefRid <= 0 THEN eb.wDebitAgentCodeIn
                     ELSE b.wDebitAgentCodeIn
                END AS wDebitAccount ,
                '' AS wDebitClientName ,
                CASE WHEN ae.wBookingRefRid <= 0 THEN eb.wDebitCustomerRid
                     ELSE b.wDebitCustomerRid
                END AS wDebitClient ,
			-- luphtc.wTitle AS PaymentMethodName,
                et.wName AS wExpenseTypeName ,
                est.wName AS wExpenseSubtypeName ,
			--luphts.wTitle AS wStatusName,
                CASE WHEN @pLangCd = 'en-gb' THEN usr.wName
                     ELSE usr.wCName
                END AS wUpdByCName ,
                CASE WHEN @pLangCd = 'en-gb' THEN crusr.wName
                     ELSE crusr.wCName
                END AS wCreatedByCName ,
                CASE WHEN ae.wBookingRefRid <= 0 THEN eb.RowID
                     ELSE b.RowID
                END AS bookingRowID ,
                CASE WHEN ae.wBookingRefRid <= 0 THEN eb.wRefNo
                     ELSE b.wRefNo
                END wRefNo ,
                eb.wRefNo AS 'wParentRefNo' ,
                eb.wBookingType AS 'wParentBookingType' ,
                CASE WHEN ae.wBookingRefRid <= 0 THEN eb.wBookingType
                     ELSE b.wBookingType
                END AS wBookingType ,
                ae.*
        FROM    dbo.eAdditionalExpense ae
                INNER JOIN dbo.eBooking eb ON eb.RowID = ae.wBookingRid
                INNER JOIN [RollsMary].[dbo].[mAgent] daAgent ON daAgent.wAgentCodeIn = eb.wDebitAgentCodeIn
                LEFT JOIN dbo.eBooking b ON b.RowID = ae.wBookingRefRid
                LEFT JOIN dbo.eBookingHeli h ON h.wBookingRid = b.RowID
                LEFT JOIN dbo.eBookingAirTicket a ON a.wBookingRid = b.RowID
                LEFT JOIN dbo.eBookingRestaurant RST ON RST.wBookingRid = b.RowID
                INNER JOIN dbo.mServiceCounter sc ON sc.RowID = eb.wDebitCounterRid
                LEFT JOIN dbo.mExpenseType et ON et.RowID = ae.wExpenseType
                LEFT JOIN dbo.mExpenseSubtype est ON est.RowID = ae.wExpenseSubtype
                LEFT JOIN [RollsMary].[dbo].[mUsr] usr ON usr.RowID = ae.wUpdBy
                LEFT JOIN [RollsMary].[dbo].[mUsr] crusr ON crusr.RowID = ae.wCrtBy
        WHERE   @pBookingRid <= 0
                OR @pBookingRid = ae.wBookingRid;
		
    END;