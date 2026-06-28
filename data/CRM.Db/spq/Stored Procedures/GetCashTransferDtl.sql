
CREATE PROCEDURE [spq].[GetCashTransferDtl] ( @pRowID BIGINT )
AS
    BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        

        SET @pRowID = ISNULL(@pRowID, 0);

        SELECT  ctd.RowID ,
                ctd.wCashTransferRid ,
                ctd.wBookingRid ,
			 ctd.wStatus ,
                ctd.wCrtBy ,
                ctd.wCrtDt ,
                ctd.wUpdBy ,
                ctd.wUpdDt ,
                'N' AS RecordState
        FROM    dbo.eCashTransferDtl ctd
        WHERE   ctd.RowID = @pRowID;
    END;