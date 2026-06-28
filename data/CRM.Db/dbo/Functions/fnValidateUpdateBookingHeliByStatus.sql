CREATE FUNCTION [dbo].[fnValidateUpdateBookingHeliByStatus] (
	@pXml xml,
	@pActionType char(1)
)

RETURNS varchar(max)
AS
BEGIN
  DECLARE @sDocHandle int;
  DECLARE @sDataSet_SetBookingHeli TABLE (
    wReqAgentCodeIn varchar(14),
    wDebitAgentCodeIn varchar(14),
    wDebitCounterRid bigint,
    wBookingRid bigint
  );
  DECLARE @errorMsg varchar(max);

  IF @pActionType != 'U'
	RETURN @errorMsg;

  EXEC sp_xml_preparedocument @sDocHandle OUTPUT,
                              @pXml;

  INSERT INTO @sDataSet_SetBookingHeli

    SELECT
      *
    FROM OPENXML(@sDocHandle, 'DataSet/SetBookingResult', 1)
    WITH (
    wReqAgentCodeIn varchar(14),
    wDebitAgentCodeIn varchar(14),
    wDebitCounterRid bigint,
    RowId bigint
	
    );

	
 -- SELECT @errorMsg=CASE when 

  --for in progress bookings.
  SELECT
    @errorMsg =
               CASE
                 WHEN eb.wReqAgentCodeIn <> sb.wReqAgentCodeIn THEN 'Can not be updated Account Requested  when booking status code is' + ebh.wBookingStatus
                 WHEN eb.wDebitAgentCodeIn <> sb.wDebitAgentCodeIn THEN 'Can not be updated Debit Account  when booking status code is ' + ebh.wBookingStatus
                 WHEN eb.wDebitCounterRid <> sb.wDebitCounterRid THEN 'Can not be updated Debit Service Counter  when booking status code is ' + ebh.wBookingStatus
               END
  FROM eBooking eb
  INNER JOIN @sDataSet_SetBookingHeli sb
    ON eb.rowId = sb.wBookingRid
  INNER JOIN ebookingheli ebh
    ON ebh.wBookingRid = eb.rowid
  WHERE ebh.wBookingStatus IN ('C', 'CL', 'UQ', 'R');

  RETURN @errorMsg;
END