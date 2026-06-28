CREATE TABLE [dbo].[eStockMovementDtl] (
    [RowID]             BIGINT          NOT NULL,
    [wStockMovementRid] BIGINT          NOT NULL,
    [wTotalCostHKD]     NUMERIC (18, 4) NOT NULL,
    [wItemRid]          BIGINT          NOT NULL,
    [wItemQty]          INT             NOT NULL,
    [wStatus]           CHAR (1)        CONSTRAINT [DF_eStockMovementDtl_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]            DATETIME2 (7)   NOT NULL,
    [wCrtBy]            BIGINT          NOT NULL,
    [wUpdDt]            DATETIME2 (7)   NOT NULL,
    [wUpdBy]            BIGINT          NOT NULL,
    [wSalesType]        VARCHAR (30)    NOT NULL,
    [wAgentCodeIn]      VARCHAR (14)    NOT NULL,
    [wPurchaseRid]      BIGINT          DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eStockMovementDtl] PRIMARY KEY CLUSTERED ([RowID] ASC)
);





