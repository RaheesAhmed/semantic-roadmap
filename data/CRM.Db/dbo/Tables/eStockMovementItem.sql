CREATE TABLE [dbo].[eStockMovementItem] (
    [RowID]                BIGINT          NOT NULL,
    [wStockMovementDtlRid] BIGINT          NOT NULL,
    [wPurchaseRid]         BIGINT          NOT NULL,
    [wQty]                 INT             NOT NULL,
    [wUnitCostHKD]         NUMERIC (18, 4) NOT NULL,
    [wStatus]              CHAR (1)        CONSTRAINT [DF_eStockMovementDtlRid_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]               DATETIME2 (7)   NOT NULL,
    [wCrtBy]               BIGINT          NOT NULL,
    [wUpdDt]               DATETIME2 (7)   NOT NULL,
    [wUpdBy]               BIGINT          NOT NULL,
    CONSTRAINT [PK_eStockMovementDtlRid] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

