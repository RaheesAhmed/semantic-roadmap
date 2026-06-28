CREATE PROC spq.GetStockSalesRefNoForShare
    @pStockSalesRid BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        SET @pStockSalesRid = ISNULL(@pStockSalesRid, 0);

        SELECT wStockSalesRid = RowID, wRefNo FROM dbo.eStockSales WHERE RowID = @pStockSalesRid;
    END;