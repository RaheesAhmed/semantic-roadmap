CREATE PROCEDURE [spq].[GetContactTranUsr]
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      

        SELECT  ctu.RowID ,
                ctu.wContactTranRid ,
                ctu.wUsrRid ,
				ctu.wDeptCd,
                ctu.wStatus ,
                ctu.wCrtDt ,
                ctu.wCrtBy ,
                ctu.wUpdDt ,
                ctu.wUpdBy
        FROM    dbo.eContactTranUsr ctu
        WHERE   ctu.RowID = @pRowID;
    END;