CREATE TABLE [dbo].[eStockAdjustment] (
    [RowID]             BIGINT         NOT NULL,
    [wWarehouseRid]     BIGINT         NOT NULL,
    [wApprovalByRid]    BIGINT         NOT NULL,
    [wAdjustDt]         DATETIME2 (7)  NOT NULL,
    [wRemarks]          NVARCHAR (500) NOT NULL,
    [wAdjustmentStatus] VARCHAR (30)   NOT NULL,
    [wStatus]           CHAR (1)       CONSTRAINT [DF_eStockAdjustment_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]            DATETIME2 (7)  NOT NULL,
    [wCrtBy]            BIGINT         NOT NULL,
    [wUpdDt]            DATETIME2 (7)  NOT NULL,
    [wUpdBy]            BIGINT         NOT NULL,
    CONSTRAINT [PK_eStockAdjustment] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

