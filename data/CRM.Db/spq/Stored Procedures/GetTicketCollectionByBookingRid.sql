CREATE PROCEDURE [spq].[GetTicketCollectionByBookingRid]
    @pBookingRid  BIGINT
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;
	
    -- Insert statements for procedure here
       SELECT  
		    tc.RowID,
		    tc.wBookingRid,
		    tc.wTicCollPoint,
		    tc.wIsCollected,
		    tc.wCollDate,
            wCollDateTime = FORMAT(tc.wCollDate, 'yyyy-MM-dd HH:mm:ss'), -- 時間
		    wCollStaff = u.wCName,
		    tc.wCollRemark,
		    tc.wSeqNo,
		    tc.wCrtDt,
		    tc.wCrtBy,
		    tc.wUpdDt,
		    tc.wUpdBy
        FROM dbo.eTicketCollection tc         
		INNER JOIN dbo.eBooking eb on eb.RowID = tc.wBookingRid
		LEFT JOIN RollsMary.dbo.mUsr u ON tc.wUpdBy = u.RowID
		WHERE @pBookingRid = tc.wBookingRid
    END;