CREATE TABLE [dbo].[eStockSales] (
    [RowID]                 BIGINT          NOT NULL,
    [wDebitCompNo]          INT             CONSTRAINT [DF_eStockSales_wSettleCounterRid] DEFAULT ((0)) NOT NULL,
    [wOutWarehouseRid]      BIGINT          NOT NULL,
    [wRefNo]                VARCHAR (50)    NOT NULL,
    [wSalesType]            VARCHAR (30)    NOT NULL,
    [wPaymentMethod]        VARCHAR (30)    NOT NULL,
    [wSalesDt]              DATETIME2 (7)   NOT NULL,
    [wSalesDeptCd]          VARCHAR (30)    NOT NULL,
    [wDebitDt]              DATETIME2 (7)   NOT NULL,
    [wSalesmanRid]          BIGINT          NOT NULL,
    [wDebitAgentCodeIn]     VARCHAR (14)    NOT NULL,
    [wRecipientAgentCodeIn] VARCHAR (14)    NOT NULL,
    [wCurrCode]             VARCHAR (6)     NOT NULL,
    [wSalesTotalPrice]      NUMERIC (18, 4) NOT NULL,
    [wExpenseAmount]        NUMERIC (18, 4) CONSTRAINT [DF_eStockSales_wExpenseAmount] DEFAULT ((0)) NOT NULL,
    [wGiftReasonCd]         VARCHAR (30)    CONSTRAINT [DF_eStockSales_wGiftReasonCd] DEFAULT ('') NOT NULL,
    [wSalesStatus]          VARCHAR (30)    NOT NULL,
    [wStatus]               CHAR (1)        CONSTRAINT [DF_eStockSales_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]                DATETIME2 (7)   NOT NULL,
    [wCrtBy]                BIGINT          NOT NULL,
    [wUpdDt]                DATETIME2 (7)   NOT NULL,
    [wUpdBy]                BIGINT          NOT NULL,
    [wCancelDebitBy]        BIGINT          NULL,
    [wCancelDebitDt]        DATETIME2 (7)   NULL,
    [wCancelBy]             BIGINT          NULL,
    [wCancelDt]             DATETIME2 (7)   NULL,
    [wCancelReasonCd]       VARCHAR (30)    CONSTRAINT [DF_eStockSales_wCancelReasonCd] DEFAULT ('') NOT NULL,
    [wCancelOtherReason]    NVARCHAR (200)  NOT NULL,
    [wDebitCounterRid]      BIGINT          CONSTRAINT [DF_eStockSales_wDebitCounterRid] DEFAULT ((0)) NOT NULL,
    [wTotalCost]            NUMERIC (18, 4) DEFAULT ((0.0000)) NOT NULL,
    [wIsBorrowGoods]        CHAR (1)        DEFAULT ('N') NOT NULL,
    [wRemark]               NVARCHAR (500)  NULL,
    [wPickupDt]             DATETIME2 (7)   NULL,
    CONSTRAINT [PK_eStockSales] PRIMARY KEY CLUSTERED ([RowID] ASC)
);
















GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eStockSales', @level2type = N'COLUMN', @level2name = N'RowID';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'總成本', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eStockSales', @level2type = N'COLUMN', @level2name = N'wTotalCost';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'借貨', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eStockSales', @level2type = N'COLUMN', @level2name = N'wIsBorrowGoods';

