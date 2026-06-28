CREATE PROCEDURE [spq].[GetCashTransferCageDtl] 
    (
      @pCashTranID BIGINT
    )
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT  ctf.RowID ,
                ctf.wAmount ,
                ctf.wCageCodeIn ,
                ctf.wCashTranID ,
                ctf.wCurrCd  
        FROM    dbo.eCashTransferCageDtl ctf
        WHERE   ctf.wCashTranID = @pCashTranID;
    END;