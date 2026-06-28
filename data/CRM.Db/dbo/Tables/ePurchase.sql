CREATE TABLE [dbo].[ePurchase] (
    [RowID]               BIGINT          NOT NULL,
    [wLotNo]              VARCHAR (50)    NOT NULL,
    [wBatchNo]            VARCHAR (50)    NOT NULL,
    [wVendorRid]          BIGINT          NOT NULL,
    [wInWarehouseRid]     BIGINT          NOT NULL,
    [wAgentCodeIn]        VARCHAR (14)    NOT NULL,
    [wCurrCode]           CHAR (3)        NOT NULL,
    [wCurrRate]           NUMERIC (12, 6) NOT NULL,
    [wCost]               NUMERIC (18, 4) NOT NULL,
    [wType]               VARCHAR (30)    NOT NULL,
    [wRemarks]            NVARCHAR (500)  NOT NULL,
    [wPurchaseStatus]     VARCHAR (30)    NOT NULL,
    [wPayExpiryDt]        DATETIME2 (7)   CONSTRAINT [DF_ePurchase_wPayExpiryDt] DEFAULT ('2099-12-31') NOT NULL,
    [wSettleBy]           BIGINT          CONSTRAINT [DF_ePurchase_wSettleBy] DEFAULT ((0)) NOT NULL,
    [wSettleDt]           DATETIME2 (7)   NULL,
    [wStatus]             CHAR (1)        CONSTRAINT [DF_ePurchase_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]              DATETIME2 (7)   NOT NULL,
    [wCrtBy]              BIGINT          NOT NULL,
    [wUpdDt]              DATETIME2 (7)   NOT NULL,
    [wUpdBy]              BIGINT          NOT NULL,
    [wNoticeRecord]       NVARCHAR (300)  NULL,
    [wStoreLocation]      NVARCHAR (300)  NULL,
    [wMaturityDate]       DATETIME2 (7)   NULL,
    [wGuestCodeIn]        VARCHAR (14)    NULL,
    [wReceiptDate]        DATETIME2 (7)   NULL,
    [wNotifier]           NVARCHAR (50)   DEFAULT ('') NOT NULL,
    [wTelephone]          VARCHAR (100)   DEFAULT ('') NOT NULL,
    [wServiceCounterRid]  BIGINT          DEFAULT ((0)) NOT NULL,
    [wPurchaseCounterRid] BIGINT          NULL,
    CONSTRAINT [PK_ePurchase] PRIMARY KEY CLUSTERED ([RowID] ASC)
);










GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'送客戶口', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchase', @level2type = N'COLUMN', @level2name = N'wGuestCodeIn';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'批次號碼', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchase', @level2type = N'COLUMN', @level2name = N'wLotNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'電話', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchase', @level2type = N'COLUMN', @level2name = N'wTelephone';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'登錄櫃台', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchase', @level2type = N'COLUMN', @level2name = N'wServiceCounterRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'收貨日期', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchase', @level2type = N'COLUMN', @level2name = N'wReceiptDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'落單服務櫃台', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchase', @level2type = N'COLUMN', @level2name = N'wPurchaseCounterRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'貨到通知人', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'ePurchase', @level2type = N'COLUMN', @level2name = N'wNotifier';

