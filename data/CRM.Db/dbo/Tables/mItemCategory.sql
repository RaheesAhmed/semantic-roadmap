CREATE TABLE [dbo].[mItemCategory] (
    [RowID]   BIGINT         NOT NULL,
    [wCName]  NVARCHAR (100) NOT NULL,
    [wEName]  VARCHAR (100)  NOT NULL,
    [wStatus] CHAR (1)       NOT NULL,
    [wCrtDt]  DATETIME2 (7)  NOT NULL,
    [wUpdDt]  DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_mItemCategory] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

