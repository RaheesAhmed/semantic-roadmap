CREATE PROCEDURE [spq].[GetContactTranParticipant]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      

        SELECT  ctp.RowID ,
                ctp.wContactTranRid ,
                ctp.wAgentCodeIn ,
                ctp.wParticipated ,
                ctp.wStatus ,
                ctp.wCrtDt ,
                ctp.wCrtBy ,
                ctp.wUpdDt ,
                ctp.wUpdBy
        FROM    dbo.eContactTranParticipant ctp
        WHERE   ctp.RowID = @pRowID;
    END;