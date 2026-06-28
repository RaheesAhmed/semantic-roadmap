CREATE TABLE [dbo].[eStockInventory] (
    [RowID]         BIGINT        NOT NULL,
    [wWarehouseRid] BIGINT        NOT NULL,
    [wPurchaseRid]  BIGINT        NOT NULL,
    [wItemRid]      BIGINT        NOT NULL,
    [wQty]          INT           NOT NULL,
    [wOnHoldQty]    INT           NOT NULL,
    [wOriQty]       INT           NOT NULL,
    [wStatus]       CHAR (1)      CONSTRAINT [DF_eStockInventory_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]        DATETIME2 (7) NOT NULL,
    [wUpdDt]        DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_eStockInventory] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

