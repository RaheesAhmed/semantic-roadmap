CREATE TABLE [dbo].[mExpenseType] (
    [RowID]        BIGINT        NOT NULL,
    [wCode]        NVARCHAR (30) NOT NULL,
    [wName]        NVARCHAR (50) NOT NULL,
    [wExpCat]      VARCHAR (30)  NOT NULL,
    [wGiftType]    VARCHAR (10)  CONSTRAINT [DF_mExpenseType_wParentCode] DEFAULT ('') NOT NULL,
    [wGiftSubtype] VARCHAR (10)  NOT NULL,
    [wSeqNo]       INT           CONSTRAINT [DF_mExpenseType_wSeqNo] DEFAULT ((0)) NOT NULL,
    [wStatus]      CHAR (1)      CONSTRAINT [DF_mExpenseType_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]       DATETIME2 (7) NOT NULL,
    [wCrtBy]       BIGINT        NOT NULL,
    [wUpdDt]       DATETIME2 (7) NOT NULL,
    [wUpdBy]       BIGINT        NOT NULL,
    CONSTRAINT [PK_mExpenseType] PRIMARY KEY CLUSTERED ([RowID] ASC)
);









