CREATE TABLE [dbo].[mEventCode] (
    [RowID]      BIGINT         NOT NULL,
    [wEventCode] NVARCHAR (30)  NOT NULL,
    [wCName]     NVARCHAR (500) NOT NULL,
    [wEName]     NVARCHAR (500) NOT NULL,
    [wRegion]    VARCHAR (10)   NOT NULL,
    [wStartDt]   DATE           NULL,
    [wEndDt]     DATE           NULL,
    [wYear]      VARCHAR (15)   NOT NULL,
    [wRemark]    NVARCHAR (500) NOT NULL,
    [wStatus]    CHAR (1)       NOT NULL,
    [wCrtDt]     DATETIME2 (7)  NOT NULL,
    [wCrtBy]     BIGINT         NOT NULL,
    [wUpdDt]     DATETIME2 (7)  NOT NULL,
    [wUpdBy]     BIGINT         NOT NULL,
    CONSTRAINT [PK_mEventCode] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



