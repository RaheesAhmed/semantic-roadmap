
-- =============================================
CREATE FUNCTION [dbo].[fnValidateBookingPickUpServiceByStatus] 
(
	@pXml xml,
	@pActionType char(1)	
	
)

RETURNS varchar(max)
AS
BEGIN
  DECLARE @sDocHandle int;
  DECLARE @sDataSet_SetBookingPickUpService TABLE (
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

  INSERT INTO @sDataSet_SetBookingPickUpService

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
                 WHEN eb.wReqAgentCodeIn <> sb.wReqAgentCodeIn THEN 'Can not be updated Account Requested  when booking status is' + ebp.wBookingStatus--mlp.wTitle
                 WHEN eb.wDebitAgentCodeIn <> sb.wDebitAgentCodeIn THEN 'Can not be updated Debit Account  when booking status is ' +ebp.wBookingStatus--mlp.wTitle
                 WHEN eb.wDebitCounterRid <> sb.wDebitCounterRid THEN 'Can not be updated Debit Service Counter  when booking status is ' +ebp.wBookingStatus--mlp.wTitle
               END
  FROM eBooking eb
  INNER JOIN @sDataSet_SetBookingPickUpService sb ON eb.rowId = sb.wBookingRid
  INNER JOIN eBookingPickUpService ebp ON ebp.wBookingRid = eb.rowid
  --INNER JOIN mLookUp mlp ON mlp.wCode=ebtg.wBookingStatus AND mlp.wType='TOUR_GUIDE_STATUS' AND wLangCd='en-GB'
  WHERE ebp.wBookingStatus IN ('C', 'CL', 'UQ', 'RF');
  RETURN @errorMsg;
END