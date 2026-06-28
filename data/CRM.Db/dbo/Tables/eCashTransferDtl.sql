CREATE TABLE [dbo].[eCashTransferDtl] (
    [RowID]            BIGINT        NOT NULL,
    [wCashTransferRid] BIGINT        NOT NULL,
    [wBookingRid]      BIGINT        NOT NULL,
    [wStatus]          CHAR (1)      NOT NULL,
    [wCrtBy]           BIGINT        NOT NULL,
    [wCrtDt]           DATETIME2 (7) NOT NULL,
    [wUpdBy]           BIGINT        NOT NULL,
    [wUpdDt]           DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_eCashTransferDtl] PRIMARY KEY CLUSTERED ([RowID] ASC),
    CONSTRAINT [FK_eCashTransferDtl_eCashTransfer] FOREIGN KEY ([wCashTransferRid]) REFERENCES [dbo].[eCashTransfer] ([RowID])
);





