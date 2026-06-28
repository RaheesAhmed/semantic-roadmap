CREATE TABLE [dbo].[eStockAdjustmentDtl] (
    [RowID]               BIGINT          NOT NULL,
    [wStockAdjustmentRid] BIGINT          NOT NULL,
    [wTotalCostHKD]       NUMERIC (18, 4) NOT NULL,
    [wItemRid]            BIGINT          NOT NULL,
    [wItemQty]            INT             NOT NULL,
    [wStatus]             CHAR (1)        CONSTRAINT [DF_eStockAjustmentDtl_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]              DATETIME2 (7)   NOT NULL,
    [wCrtBy]              BIGINT          NOT NULL,
    [wUpdDt]              DATETIME2 (7)   NOT NULL,
    [wUpdBy]              BIGINT          NOT NULL,
    [wAdjustGroup]        INT             CONSTRAINT [DF__eStockAdj__wAdju__73DC8E19] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_eStockAjustmentDtl] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



