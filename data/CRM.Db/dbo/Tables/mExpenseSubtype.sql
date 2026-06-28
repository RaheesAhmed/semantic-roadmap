CREATE TABLE [dbo].[mExpenseSubtype] (
    [RowID]          BIGINT        NOT NULL,
    [wCode]          NVARCHAR (30) NOT NULL,
    [wName]          NVARCHAR (50) NOT NULL,
    [wExpenseTypeId] BIGINT        NOT NULL,
    [wExpCat]        VARCHAR (30)  NOT NULL,
    [wGiftType]      VARCHAR (10)  NOT NULL,
    [wGiftSubtype]   VARCHAR (10)  NOT NULL,
    [wStatus]        CHAR (1)      NOT NULL,
    [wSeqNo]         INT           NOT NULL,
    [wCrtDt]         DATETIME2 (7) NOT NULL,
    [wCrtBy]         BIGINT        NOT NULL,
    [wUpdDt]         DATETIME2 (7) NOT NULL,
    [wUpdBy]         BIGINT        NOT NULL,
    CONSTRAINT [PK_mExpenseSubtype] PRIMARY KEY CLUSTERED ([RowID] ASC)
);





