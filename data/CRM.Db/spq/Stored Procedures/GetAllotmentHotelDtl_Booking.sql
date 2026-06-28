
CREATE PROCEDURE [spq].[GetAllotmentHotelDtl_Booking]
    (      
	  @pwAllotmentHotelRid  bigint
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
			
       SELECT  
		mraqd.RowID,	
		mraqd.wAllotmentHotelRid,				
		mraqd.wAllotmentGroupRid,
		mra.wName wRoomAllotmentName,
		mraqd.wSunQty,
		mraqd.wMonQty,
		mraqd.wTueQty,
		mraqd.wWedQty,
		mraqd.wThuQty,
		mraqd.wFriQty,
		mraqd.wSatQty,
		mraqd.wSeqNo,		
		mraqd.wCrtDt,
		mraqd.wCrtBy,
		mraqd.wUpdDt,
		mraqd.wUpdBy
        FROM    dbo.eAllotmentHotelDtl mraqd
		inner join dbo.eAllotmentHotel mraq on mraq.RowID = mraqd.wAllotmentHotelRid
		inner join dbo.mAllotmentGroup mra on mra.RowID = mraqd.wAllotmentGroupRid	  

	WHERE   
		( @pwAllotmentHotelRid = ''
            OR @pwAllotmentHotelRid IS NULL
            OR @pwAllotmentHotelRid = mraqd.wAllotmentHotelRid
        );

    END;