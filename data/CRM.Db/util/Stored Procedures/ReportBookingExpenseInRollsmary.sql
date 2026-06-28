-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [util].[ReportBookingExpenseInRollsmary]
AS
BEGIN
IF @@trancount = 0
	SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

DECLARE @vNow DATETIME2 = GETDATE();

DECLARE @vStatus TABLE (
	wStatus VARCHAR(20),
	wMapTo VARCHAR(20)
)

INSERT INTO 
	@vStatus (wStatus, wMapTo)
VALUES
	('C','C'), ('RF','C'), ('RF','RF');


CREATE TABLE #tmpBooking (
	wBookingRid VARCHAR(40),
	wBookingSubRid BIGINT,
	wRefNo	VARCHAR(50),
	wSubRefNo VARCHAR(50),
	wBookingStatus VARCHAR(10),
	wSubBookingStatus VARCHAR(10),
	wDebitCounterRid BIGINT,
	wDebitAgentCodeIn VARCHAR(20),
	wExpAmt NUMERIC(18, 4),
	wTotalAmt NUMERIC(18, 4),
	wPaymentMethod VARCHAR(50),
	wBookingType VARCHAR(50),
	wDebitDt	DATETIME2,
	wCancelDebitDt DATETIME2,
	wUpdBy BIGINT,
	wCrtDt DATETIME2,
	wUpdDt DATETIME2,
	wPersonRid	BIGINT,
	wMissingExpTran CHAR DEFAULT 'N',
	wReceiptNo NVARCHAR(100),
	wOrderNo NVARCHAR(100),
	wRoomNo VARCHAR(50)
)

INSERT INTO
	#tmpBooking(wBookingType, wBookingRid, wRefNo, wSubRefNo, wBookingSubRid, 
	wBookingStatus, wSubBookingStatus, wDebitCounterRid, wDebitAgentCodeIn, wExpAmt, wTotalAmt, wPaymentMethod,
	wDebitDt, wCancelDebitDt, wUpdBy, wCrtDt, wUpdDt, wPersonRid, wReceiptNo, wOrderNo, wRoomNo
	)
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingFerry bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'FERRY' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION 
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eAdditionalExpense bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'ADDITIONALEXPENSES' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpenseAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingLeading bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'LEADING_SERVICE' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingVisa bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'VISA' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpenseAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingShow bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'SHOWTICKET' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingPrivatePlane bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'PP' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpenseAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingPickUpService bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'PickUp_SERVICE' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingHeli bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'HELI' AND b.wCrtDt >= '2017-08-31 08:03:00' AND bf.wIsCharteredFlight = 'Y'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', pd.RowID, wBookingStatus = s.wMapTo, pd.wPassengerBookingStatus, b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, pd.wPersonRid,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingHeli bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'HELI' AND b.wCrtDt >= '2017-08-31 08:03:00' AND bf.wIsCharteredFlight = 'N'
INNER JOIN
	dbo.ePassengerDetails pd ON bf.wBookingRid = pd.wBookingRid AND pd.wType = 'HELI'
INNER JOIN
	@vStatus s ON pd.wPassengerBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', pd.RowID, wBookingStatus = s.wMapTo, pd.wPassengerBookingStatus, b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	pd.wAmount, pd.wAmount, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, pd.wPersonRid,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingAirTicket bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'AIRTICKET' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	dbo.ePassengerDetails pd ON bf.wBookingRid = pd.wBookingRid AND pd.wType = 'AIRTICKET'
INNER JOIN
	@vStatus s ON pd.wPassengerBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, '', 0, wBookingStatus = s.wMapTo, '', b.wDebitCounterRid, b.wDebitAgentCodeIn, 
	bf.wExpAmt, bf.wTotalAmt, bf.wPaymentMethod, b.wDebitDt, b.wCancelDebitDt, bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wReceiptNo, bf.wOrderNo, ''
FROM
	dbo.eBooking b
INNER JOIN
	dbo.eBookingCheckInService bf ON b.RowID = bf.wBookingRid AND b.wBookingType = 'CHK_IN_SVC' AND b.wCrtDt >= '2017-08-31 08:03:00'
INNER JOIN
	@vStatus s ON bf.wBookingStatus = s.wStatus
UNION
SELECT
	b.wBookingType, b.RowID, b.wRefNo, bRoom.wRefNo, br.RowID, wBookingStatus = 'C', bf.wAction, b.wDebitCounterRid, ISNULL(bChange.wDebitAgentCodeIn, b.wDebitAgentCodeIn), 
	wExpAmt = CASE WHEN bf.wAction = 'C' THEN bf.wTotalAmount ELSE bf.wAmountChange END, 
	wTotalAmt = CASE WHEN bf.wAction = 'C' THEN bf.wTotalAmount ELSE bf.wAmountChange END, 
	bf.wPaymentMethod, ISNULL(bChange.wDebitDt, b.wDebitDt), ISNULL(bChange.wCancelDebitDt, b.wCancelDebitDt), bf.wUpdBy, bf.wCrtDt, bf.wUpdDt, -1,
	bf.wCashReceiptNo, br.wOrderNo, br.wRoomNo
FROM
	dbo.eHotelChange bf
INNER JOIN
	dbo.eBookingRoom br ON bf.wRoomBookingRid = br.RowID
INNER JOIN
	dbo.eBookingHotel bh ON bh.RowID = br.wHotelBookingRid
INNER JOIN
	dbo.eBooking b ON bh.wBookingRid = b.RowID AND b.wBookingType = 'HOTEL' AND b.wCrtDt >= '2017-08-31 08:03:00'
LEFT JOIN
	dbo.eBooking bChange ON bChange.RowID = bf.wBookingRid AND bChange.wBookingType = 'CHANGEHOTEL'
LEFT JOIN
	dbo.eBooking bRoom ON br.wBookingRid = bRoom.RowID AND bRoom.wBookingType = 'ROOM'
--   select distinct 'WHEN ''' + wBookingType + ''' THEN ' from eBooking

UPDATE
	tmp
SET
	wMissingExpTran = 'Y'
FROM
	#tmpBooking tmp
LEFT JOIN
	Rollsmary.dbo.eExpTran et ON tmp.wBookingRid = et.wReferId and (tmp.wBookingSubRid = 0 OR tmp.wBookingSubRid = et.wRefRid)
where 
	et.RowID is null

-- For Report Checking
SELECT
	wDebitAgentCode = a.wAgentCode_Display,
	wCounterName = sc.wName,
	wBookStatus = CASE tmp.wBookingStatus WHEN 'C' THEN N'完成' ELSE N'退款' END,
	wRoomBookingStatus = lp.wTitle ,
	tmp.wRefNo, tmp.wSubRefNo,
	N'消費金額' = tmp.wExpAmt, 
	N'總值' = tmp.wTotalAmt,
	wSep = '|||',
	et.wDate,
	et.wRemark,
	et.wAmount, 
	et.wAmountActual_CRM,
	et.RowID
--	tmp.*, et.*
FROM
	#tmpBooking tmp
LEFT JOIN
	Rollsmary.dbo.eExpTran et ON tmp.wBookingRid = et.wReferId and (tmp.wBookingSubRid = 0 OR tmp.wBookingSubRid = et.wRefRid)
INNER JOIN
	Rollsmary.dbo.mAgent a ON tmp.wDebitAgentCodeIn = a.wAgentCodeIn
INNER JOIN
	CRM.dbo.mServiceCounter sc on tmp.wDebitCounterRid = sc.RowID
LEFT JOIN
	(select wCode, wTitle = Min(wTitle) from crm.dbo.mLookUp where  wType like '%payment%' and wLangCd = 'zh-TW' GROUP BY wCode) lp ON lp.wCode = tmp.wSubBookingStatus

END