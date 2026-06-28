CREATE PROCEDURE [spq].[GetPointsTradingRemarks]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   

        SELECT  ptr.RowID ,
                ptr.wPointsTradingRid ,
                ptr.wRemarks ,
				ptr.wStatus,
                ptr.wCrtBy ,
                ptr.wCrtDt ,
                ptr.wUpdDt ,
                ptr.wUpdBy
        FROM    dbo.ePointsTradingRemarks ptr
        WHERE   ptr.RowID = @pRowID;
    END;