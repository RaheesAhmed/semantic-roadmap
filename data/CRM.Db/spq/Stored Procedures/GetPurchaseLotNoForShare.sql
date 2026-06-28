CREATE PROC spq.GetPurchaseLotNoForShare
    @pPurchaseRid BIGINT
AS
    BEGIN
        SET @pPurchaseRid = ISNULL(@pPurchaseRid, 0);

        SELECT
            wPurchaseRid = RowID,
            wLotNo = RIGHT(wLotNo,LEN(wLotNo)- 7),
            wBatchNo
        FROM dbo.ePurchase
        WHERE RowID = @pPurchaseRid;
    END;