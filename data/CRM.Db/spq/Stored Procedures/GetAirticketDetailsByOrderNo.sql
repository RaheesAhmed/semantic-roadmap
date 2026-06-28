CREATE PROCEDURE [spq].[GetAirticketDetailsByOrderNo]
(
	@pOrderNo NVARCHAR (50),
	@pLangCd VARCHAR(10) = 'en-gb'
)
AS
BEGIN
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	
	IF @@trancount = 0
		SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

	SELECT
		ebat.RowID
		,ebat.wBookingRid
		,wOrderNo
		,(CASE WHEN @pLangCd = 'en-gb' THEN dap.wEName ELSE dap.wCName END) +', '+ISNULL(dplup.wTitle,'') AS wDepartureTerminal
		,(CASE WHEN @pLangCd = 'en-gb' THEN aap.wEName ELSE aap.wCName END) +', '+ISNULL(aplup.wTitle,'') AS wArrivalTerminal
		,RTD.wArrivalAirportRid
		,RTD.wDepartureAirportRid
		,rtd.wDepartFlightNo AS wFlightNo
		,rtd.wArrivalDt wArrivalDateTime
		,rtd.wTakeOffDt AS wDepartureDateTime
		,rtd.wAirline
		FROM dbo.eBookingAirTicket ebat
				LEFT JOIN (SELECT wArrivalAirportRid,wTypeRid,wDepartureAirportRid,wFlightType,wArrivalDt,wDepartFlightNo,wTakeOffDt,wAirline
							FROM dbo.eAirTicketRouteDtl
							WHERE wType='AIRTICKET' AND wLine=1 AND wStatus='A' ) rtd ON rtd.wTypeRid=ebat.RowID
			LEFT JOIN dbo.mAirport aap ON aap.RowID=RTD.wArrivalAirportRid
			LEFT JOIN mLookUp aplup ON aplup.wCode = aap.wCity AND aplup.wType = 'CITY' AND aplup.wLangCd=@pLangCd
			LEFT JOIN dbo.mAirport dap ON dap.RowID=RTD.wDepartureAirportRid
			LEFT JOIN mLookUp dplup ON dplup.wCode = dap.wCity AND dplup.wType = 'CITY' AND dplup.wLangCd=@pLangCd			
		WHERE ( wOrderNo=@pOrderNo);
END;