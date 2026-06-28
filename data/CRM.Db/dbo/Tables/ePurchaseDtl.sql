CREATE TABLE [dbo].[ePurchaseDtl] (
    [RowID]         BIGINT          NOT NULL,
    [wPurchaseRid]  BIGINT          NOT NULL,
    [wCurrCode]     VARCHAR (3)     NOT NULL,
    [wCurrRate]     NUMERIC (12, 6) NOT NULL,
    [wUnitCost]     NUMERIC (18, 4) NOT NULL,
    [wQty]          INT             NOT NULL,
    [wItemRid]      BIGINT          NOT NULL,
    [wStatus]       CHAR (1)        CONSTRAINT [DF_ePurchaseDtl_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]        DATETIME2 (7)   NOT NULL,
    [wCrtBy]        BIGINT          NOT NULL,
    [wUpdDt]        DATETIME2 (7)   NOT NULL,
    [wUpdBy]        BIGINT          NOT NULL,
    [wStockInQty]   INT             CONSTRAINT [DF_ePurchaseDtl_wStockInQty] DEFAULT ((0)) NOT NULL,
    [wValidDate]    DATETIME2 (7)   NULL,
    [wHandleStatus] VARCHAR (10)    DEFAULT ('') NOT NULL,
    [wHandleRemark] NVARCHAR (500)  DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ePurchaseDtl] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'處理狀況', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchaseDtl', @level2type = N'COLUMN', @level2name = N'wHandleStatus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'處理備註 ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchaseDtl', @level2type = N'COLUMN', @level2name = N'wHandleRemark';

