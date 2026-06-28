CREATE TABLE [dbo].[eCashTransfer] (
    [RowID]                BIGINT          NOT NULL,
    [wRefNo]               VARCHAR (30)    NOT NULL,
    [wInCounterRid]        BIGINT          NOT NULL,
    [wInAgentCodeIn]       VARCHAR (14)    NOT NULL,
    [wOutAgentCodeIn]      VARCHAR (14)    NOT NULL,
    [wIsAuthorized]        CHAR (1)        CONSTRAINT [DF_eCashTransfer_wIsAuthorizedTransfer] DEFAULT ('N') NOT NULL,
    [wInCurrCd]            VARCHAR (30)    CONSTRAINT [DF_eCashTransfer_wInCurrCd] DEFAULT ('') NOT NULL,
    [wOutCurrCd]           VARCHAR (30)    NOT NULL,
    [wInCurrRate]          NUMERIC (18, 4) CONSTRAINT [DF_eCashTransfer_wInCurrRate] DEFAULT ((0)) NOT NULL,
    [wOutCurrRate]         NUMERIC (18, 4) NOT NULL,
    [wInAmount]            NUMERIC (18, 4) CONSTRAINT [DF_eCashTransfer_wInAmount] DEFAULT ((0)) NOT NULL,
    [wOutAmount]           NUMERIC (18, 4) CONSTRAINT [DF_eCashTransfer_wAmount] DEFAULT ((0)) NOT NULL,
    [wIsAutoAdjust]        CHAR (1)        CONSTRAINT [DF_eCashTransfer_wIsAutoAdjust] DEFAULT ('Y') NOT NULL,
    [wTranDt]              DATETIME2 (7)   NULL,
    [wRollexCompNo]        INT             CONSTRAINT [DF_eCashTransfer_wRollexCompNo] DEFAULT ((0)) NOT NULL,
    [wDepositor]           NVARCHAR (100)  CONSTRAINT [DF_eCashTransfer_wDepositor] DEFAULT ('') NOT NULL,
    [wRemark]              NVARCHAR (500)  NOT NULL,
    [wStatus]              CHAR (1)        CONSTRAINT [DF_eCashTransfer_wStatus] DEFAULT ('A') NOT NULL,
    [wCashTransferStatus]  VARCHAR (5)     NOT NULL,
    [wTransferGUID]        VARCHAR (30)    NOT NULL,
    [wRelatedBookingRefNo] VARCHAR (500)   NOT NULL,
    [wCrtBy]               BIGINT          NOT NULL,
    [wCrtDt]               DATETIME2 (7)   NOT NULL,
    [wUpdBy]               BIGINT          NOT NULL,
    [wUpdDt]               DATETIME2 (7)   NOT NULL,
    [wIsByPass]            CHAR (1)        CONSTRAINT [DF_eCashTransfer_wIsByPass] DEFAULT ('N') NOT NULL,
    [wIsIVRProcess]        CHAR (1)        CONSTRAINT [DF_eCashTransfer_wIsIVRProcess] DEFAULT ('Y') NOT NULL,
    [wExchangeFxRate]      NUMERIC (12, 6) DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eCashTransfer] PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'電話認證', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eCashTransfer', @level2type = N'COLUMN', @level2name = N'wIsIVRProcess';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'跳過戶口認證', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eCashTransfer', @level2type = N'COLUMN', @level2name = N'wIsByPass';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'貨幣轉換率', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eCashTransfer', @level2type = N'COLUMN', @level2name = N'wExchangeFxRate';

