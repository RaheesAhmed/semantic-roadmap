CREATE FUNCTION [dbo].[fnValidateUpdateCheckInServiceByStatus] (
	@pXml xml,
	@pActionType char(1)
)

RETURNS VARCHAR(MAX)
AS
BEGIN
  DECLARE @sDocHandle INT;
  DECLARE @sDataSet_SetBookingCheckInService TABLE (
    wReqAgentCodeIn VARCHAR(14),
    wDebitAgentCodeIn VARCHAR(14),
    wDebitCounterRid BIGINT,
    wBookingRid BIGINT
  );
  DECLARE @errorMsg VARCHAR(MAX);

  IF @pActionType != 'U'
	RETURN @errorMsg;

  EXEC sp_xml_preparedocument @sDocHandle OUTPUT,
                              @pXml;

  INSERT INTO @sDataSet_SetBookingCheckInService

    SELECT
      *
    FROM OPENXML(@sDocHandle, 'DataSet/SetBookingResult', 1)
    WITH (
		wReqAgentCodeIn VARCHAR(14),
		wDebitAgentCodeIn VARCHAR(14),
		wDebitCounterRid BIGINT,
		RowId BIGINT
    );

  SELECT
    @errorMsg =
               CASE
                 WHEN b.wReqAgentCodeIn <> tmp.wReqAgentCodeIn THEN 'Can not be updated Account Requested  when booking status code is' + cs.wBookingStatus
                 WHEN b.wDebitAgentCodeIn <> tmp.wDebitAgentCodeIn THEN 'Can not be updated Debit Account  when booking status code is ' + cs.wBookingStatus
                 WHEN b.wDebitCounterRid <> tmp.wDebitCounterRid THEN 'Can not be updated Debit Service Counter  when booking status code is ' + cs.wBookingStatus
               END
  FROM eBooking b
  INNER JOIN @sDataSet_SetBookingCheckInService tmp ON b.rowId = tmp.wBookingRid
  INNER JOIN eBookingCheckInService cs ON cs.wBookingRid = b.rowid 
  WHERE cs.wBookingStatus IN ('C', 'CL', 'UQ', 'R');

  RETURN @errorMsg;
END