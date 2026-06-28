CREATE FUNCTION [dbo].[GetRollingValues]
(
	@hotelBookingRequestId BIGINT
) 
RETURNS @output TABLE(mCompanyRolling NUMERIC(18,4),mBaseRolling NUMERIC 
) 
BEGIN 

	INSERT INTO @output (mCompanyRolling,mBaseRolling)  
	SELECT SUM(TempValue.mCompanyRolling) as mCompanyRolling, SUM(TempValue.mBaseRolling) as mBaseRolling FROM (
	SELECT 
	(ISNULL((SELECT 
				wRolling 
				FROM RollsMary.dbo.mAgentBalRollingMth 
				WHERE
				wAgentCodeIn = ehr.wReqAgentCodeIn
				AND
				wYearMth = (SELECT  CONCAT(wYear, wMonth) FROM RollsMary.dbo.mSettlePeriod WHERE wCompNo = (SELECT wRollexCompNo FROM CRM.dbo.mServiceCounter WHERE RowID = ehrdtl.wCounterRid) AND RollsMary.dbo.fnUTC8Now() BETWEEN wStartDateTime AND wEndDateTime)
				AND
				wCompNo = (SELECT wRollexCompNo FROM CRM.dbo.mServiceCounter WHERE RowID = ehrdtl.wCounterRid)),0)) 
				as mCompanyRolling,
			
				(ISNULL((SELECT 
				SUM(wRollingHKD) 
				FROM RollsMary.dbo. mAgentBalRollingMth 
				WHERE
				wAgentCodeIn = ehr.wReqAgentCodeIn
				AND
				wYearMth = (SELECT CONCAT(wYear, wMonth) FROM RollsMary.dbo.mSettlePeriod WHERE wCompNo = (SELECT wRollexCompNo FROM CRM.dbo.mServiceCounter WHERE RowID = ehrdtl.wCounterRid) AND RollsMary.dbo.fnUTC8Now() BETWEEN wStartDateTime AND wEndDateTime)),0))
				as mBaseRolling
	FROM eHotelRequest ehr
	INNER JOIN eHotelRequestDtl ehrdtl ON ehr.RowID = ehrdtl.wHotelRequestRid
	WHERE ehr.RowID = @hotelBookingRequestId ) TempValue

	
    RETURN 
END