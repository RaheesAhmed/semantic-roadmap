CREATE PROCEDURE [spq].[GetPassengerDuplicateValues]
@pPassengerRid BIGINT,
@pBookingType VARCHAR(20)=NULL,
@pColumnName VARCHAR(30),
@pValue VARCHAR(100)
AS
BEGIN
	IF @pBookingType='AIRTICKET' AND @pColumnName='wClientTicketNo'
	BEGIN
		SELECT  RowID,
				wClientTicketNo AS wDuplicateValue
		FROM dbo.ePassengerDetails
		WHERE wType = 'AIRTICKET'
			AND @pValue IS NOT NULL
			AND @pValue !=''
			AND RowID <> @pPassengerRid			
			AND wClientTicketNo COLLATE Latin1_General_CS_AS = @pValue COLLATE Latin1_General_CS_AS;
	END;
END