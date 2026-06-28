CREATE PROCEDURE [spq].[GetRoomAllotmentServiceCounter]-- 19000000010010
(
  @pRoomAllotmentNameRid  bigint
)  
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here	
       SELECT  
		mrasc.RowID,
		mrasc.wAllotmentGroupRid,
		mrasc.wCounterRid,
		msc.wCode,
		msc.wName,
		msc.wSmsRoomID,
		msc.wRollexCompNo,
		msc.wRegion,
		msc.wDefaultHotelCode,
		msc.wCurrCode,
		msc.wRemark,				
		--mrasc.RowID wSeqNo,
		mrasc.wCrtDt,
		mrasc.wCrtBy,
		mrasc.wUpdDt,
		mrasc.wUpdBy
        FROM  dbo.mAllotmentGroupDtl mrasc
		inner join dbo.mAllotmentGroup mrl on mrl.RowID = mrasc.wAllotmentGroupRid
		inner join dbo.mServiceCounter msc ON msc.RowID = mrasc.wCounterRid
		
		WHERE   
		( @pRoomAllotmentNameRid = ''
            OR @pRoomAllotmentNameRid IS NULL
            OR @pRoomAllotmentNameRid = mrasc.wAllotmentGroupRid
        );
			
    END;