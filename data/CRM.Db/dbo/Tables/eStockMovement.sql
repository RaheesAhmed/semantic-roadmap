CREATE TABLE [dbo].[eStockMovement] (
    [RowID]            BIGINT         NOT NULL,
    [wOutWarehouseRid] BIGINT         NOT NULL,
    [wOutUsrRid]       BIGINT         NOT NULL,
    [wOutDt]           DATETIME2 (7)  NOT NULL,
    [wInWarehouseRid]  BIGINT         NOT NULL,
    [wInUsrRid]        BIGINT         NOT NULL,
    [wInDt]            DATETIME2 (7)  NULL,
    [wRemarks]         NVARCHAR (500) NOT NULL,
    [wMovementStatus]  VARCHAR (30)   NOT NULL,
    [wStatus]          CHAR (1)       CONSTRAINT [DF_eStockMovement_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]           DATETIME2 (7)  NOT NULL,
    [wCrtBy]           BIGINT         NOT NULL,
    [wUpdDt]           DATETIME2 (7)  NOT NULL,
    [wUpdBy]           BIGINT         NOT NULL,
    CONSTRAINT [PK_eStockMovement] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



