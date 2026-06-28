CREATE PROCEDURE [spq].[GetPassengerDetailsByAirTicketNo] 
(
	@pStatus  CHAR (1) = NULL,
	@pTicketNo VARCHAR(20) = NULL,
	@pLangCd VARCHAR(10) = 'en-gb'
)
AS
BEGIN

IF @@trancount = 0 SET TRANSACTION ISOLATION LEVEL SNAPSHOT; 

SELECT   pd.RowID
		,CASE WHEN PSDEP.wType='PASSENGER' THEN PSARL.wTitle ELSE ARL.wTitle  END AS wAirline

		,CASE WHEN PSDEP.wType='PASSENGER' THEN PSDEP.wDepartFlightNo ELSE ARTRT.wDepartFlightNo END AS wDepartFlightNo	

		,pd.wClientTicketNo
		,pd.wRequesterAcc
		,CASE WHEN PSDEP.wType='PASSENGER' THEN PSDEP.wTakeOffDt ELSE ARTRT.wTakeOffDt END AS wTakeOffDateTime

		,pd.wPassengerBookingStatus
		,bat.wOrderNo
		,pd.wPersonRid

		,(CASE WHEN PSDEP.wType='PASSENGER' THEN COALESCE((PARRT.wCode +', '+ CASE WHEN @pLangCd = 'en-gb' THEN PARRT.wEName ELSE PARRT.wCName END + ', '+PLCTAR.wTitle),' ') 
			   ELSE COALESCE((ADPPRT.wCode+', '+ CASE WHEN @pLangCd = 'en-gb' THEN ADPPRT.wEName ELSE ADPPRT.wCName END + ', '+ALCTDR.wTitle),' ')  END) AS wArrivalTerminal

		,pd.wBookingRid
FROM 
		(SELECT * FROM ePassengerDetails WHERE (@pStatus = ' ' OR @pStatus = '' OR @pStatus IS NULL OR @pStatus = wPassengerBookingStatus)
			AND (@pTicketNo IS NULL OR wClientTicketNo = @pTicketNo) AND wClientTicketNo !='') pd
		INNER JOIN eBookingAirTicket bat ON bat.wBookingRid = pd.wBookingRid

		--- for default routes	
		-- departure	
		INNER JOIN (SELECT * FROM dbo.eAirTicketRouteDtl WHERE wType='AIRTICKET' AND wStatus='A' AND wLine=1 AND wIsReturn='N')
		ARTRT ON ARTRT.wTypeRid=bat.RowID
		LEFT JOIN (SELECT * FROM dbo.mLookUp WHERE wType='AIRLINES' AND wStatus='A' AND wLangCd=@pLangCd) ARL ON ARL.wCode = ARTRT.wAirline		

		--- destination
		INNER JOIN (SELECT *,ROW_NUMBER() OVER(PARTITION BY wTypeRid ORDER BY wLine DESC) AS LastRec
				FROM dbo.eAirTicketRouteDtl WHERE wType='AIRTICKET' AND wStatus='A' AND wIsReturn='N')
		ARTDEST ON ARTDEST.wTypeRid=bat.RowID AND ARTDEST.LastRec=1		
		LEFT JOIN (SELECT * FROM dbo.mAirport) ADPPRT ON ADPPRT.RowID=ARTDEST.wArrivalAirportRid		
		LEFT JOIN (SELECT * FROM dbo.mLookUp  WHERE wType='CITY'  AND wStatus='A' AND wLangCd=@pLangCd) ALCTDR ON ALCTDR.wCode=ADPPRT.wCity
		
		-- for passenger routes
		-- departure	
		LEFT JOIN (SELECT * FROM dbo.eAirTicketRouteDtl WHERE wType='PASSENGER' AND wStatus='A' AND wLine=1 AND wIsReturn='N')
		PSDEP ON PSDEP.wTypeRid=pd.RowID
		LEFT JOIN (SELECT * FROM dbo.mLookUp WHERE wType='AIRLINES' AND wStatus='A' AND wLangCd=@pLangCd) PSARL ON PSARL.wCode = PSDEP.wAirline	

		--destinatoin
		LEFT JOIN (SELECT *,ROW_NUMBER() OVER(PARTITION BY wTypeRid ORDER BY wLine DESC) AS ReturnFistRt 
				FROM dbo.eAirTicketRouteDtl WHERE wType='PASSENGER' AND wStatus='A' AND wIsReturn='N')
		PSDRRT ON PSDRRT.wTypeRid=pd.RowID AND PSDRRT.ReturnFistRt=1
						
		LEFT JOIN (SELECT * FROM dbo.mAirport) PARRT ON PARRT.RowID=PSDRRT.wArrivalAirportRid		
		LEFT JOIN (SELECT * FROM dbo.mLookUp WHERE wType='CITY'  AND wStatus='A' AND wLangCd=@pLangCd) PLCTAR ON PLCTAR.wCode=PARRT.wCity;

END;