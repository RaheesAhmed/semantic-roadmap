CREATE TABLE [dbo].[eStockSalesDtl] (
    [RowID]          BIGINT          NOT NULL,
    [wStockSalesRid] BIGINT          NOT NULL,
    [wItemRid]       BIGINT          NOT NULL,
    [wTotalCostHKD]  NUMERIC (18, 4) NOT NULL,
    [wTotalPriceHKD] NUMERIC (18, 4) NOT NULL,
    [wQty]           INT             NOT NULL,
    [wStatus]        CHAR (1)        CONSTRAINT [DF_eStockSalesDtl_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]         DATETIME2 (7)   NOT NULL,
    [wCrtBy]         BIGINT          NOT NULL,
    [wUpdDt]         DATETIME2 (7)   NOT NULL,
    [wUpdBy]         BIGINT          NOT NULL,
    [wUnitPriceHKD]  NUMERIC (18, 4) NOT NULL,
    [wLotNo]         VARCHAR (50)    DEFAULT ('') NULL,
    CONSTRAINT [PK_eStockSalesDtl] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'批次號碼', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eStockSalesDtl', @level2type = N'COLUMN', @level2name = N'RowID';

