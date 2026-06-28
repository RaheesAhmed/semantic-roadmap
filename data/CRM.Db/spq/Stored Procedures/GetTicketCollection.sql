CREATE PROCEDURE [spq].[GetTicketCollection]
    (
       @pwBookingRid  bigint
    )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
       SELECT  
		etc.RowID,
		etc.wBookingRid,
		etc.wTicCollPoint,
		etc.wIsCollected,
		etc.wCollDate,
		wCollStaff = u.wCName,
		etc.wCollRemark,
		etc.wSeqNo,
		etc.wCrtDt,
		etc.wCrtBy,
		etc.wUpdDt,
		etc.wUpdBy
        FROM    
			dbo.eTicketCollection etc         
		inner join 
			dbo.eBooking eb on eb.RowID = etc.wBookingRid
		LEFT JOIN
			RollsMary.dbo.mUsr u ON etc.wUpdBy = u.RowID
		WHERE   
		( @pwBookingRid = ''
            OR @pwBookingRid IS NULL
            OR @pwBookingRid = etc.wBookingRid
        );

    END;