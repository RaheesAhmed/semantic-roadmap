CREATE PROCEDURE [spq].[GetUnqualified] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      

        SELECT  uq.RowID ,
                uq.wAgentCodeIn ,
				uq.wBookingRid ,
				uq.wBookingType ,
                uq.wDeptCd ,
				uq.wCounterRid ,
                uq.wCompNo ,
                uq.wUnqualifiedType ,
                uq.wUnqualifiedStatus ,
                uq.wReason ,
                uq.wDetails ,
                uq.wFollowUpDetails ,
				uq.wStatus,
                uq.wCrtDt ,
                uq.wCrtBy ,
                uq.wUpdDt ,
                uq.wUpdBy
        FROM    dbo.eUnqualified uq
        WHERE   uq.RowID = @pRowID;
    END;