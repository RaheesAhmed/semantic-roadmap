CREATE TABLE [dbo].[eCashTransferCageDtl] (
    [RowID]       BIGINT          NOT NULL,
    [wCashTranID] BIGINT          NOT NULL,
    [wCageCodeIn] VARCHAR (14)    NOT NULL,
    [wAmount]     NUMERIC (18, 4) NOT NULL,
    [wCurrCd]     VARCHAR (30)    NOT NULL,
    [wCurrRate]   NUMERIC (18, 4) NOT NULL,
    [wCrtBy]      BIGINT          NOT NULL,
    [wCrtDt]      DATETIME2 (7)   NOT NULL,
    [wUpdBy]      BIGINT          NOT NULL,
    [wUpdDt]      DATETIME2 (7)   NOT NULL,
    CONSTRAINT [PK_eCashTransferCageDtl] PRIMARY KEY CLUSTERED ([RowID] ASC),
    CONSTRAINT [FK_eCashTransferCageDtl_eCashTransfer] FOREIGN KEY ([wCashTranID]) REFERENCES [dbo].[eCashTransfer] ([RowID])
);

