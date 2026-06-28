CREATE TABLE [dbo].[mVoucher] (
    [RowID]            BIGINT          NOT NULL,
    [wCounterRID]      BIGINT          NOT NULL,
    [wCorporateRID]    BIGINT          NOT NULL,
    [wVoucherRefNo]    BIGINT          NOT NULL,
    [wVoucherType]     NVARCHAR (50)   CONSTRAINT [DF_mVoucher_wVoucherType] DEFAULT ('') NOT NULL,
    [wVoucherValue]    DECIMAL (18, 4) NOT NULL,
    [wVoucherCurrCode] VARCHAR (3)     NOT NULL,
    [wRemark]          NVARCHAR (300)  CONSTRAINT [DF_mVoucher_wRemark] DEFAULT ('') NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_mVoucher_wStatus_1] DEFAULT ('A') NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   CONSTRAINT [DF_mVoucher_wUpdDt] DEFAULT ([dbo].[fnUTC8Now]()) NOT NULL,
    [wVoucherStatus]   CHAR (1)        CONSTRAINT [DF_mVoucher_wStatus] DEFAULT ('A') NOT NULL,
    CONSTRAINT [PK_mVoucher] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



