-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [spq].[GetRoomAllotmentByRoomID]
	(
	@wRoomRid bigint,
	@wIsSpecialDate Char(1)
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select wStartDate,
	wEndDate
	from eAllotmentHotel
	where wRoomRid=@wRoomRid  AND wIsSpecialDate=@wIsSpecialDate
END