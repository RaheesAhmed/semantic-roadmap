CREATE TABLE [dbo].[mShowTicketPrice] (
    [RowID]       BIGINT          NOT NULL,
    [wShowRid]    BIGINT          NOT NULL,
    [wTicketType] NVARCHAR (50)   NOT NULL,
    [wAmount]     NUMERIC (18, 2) NOT NULL,
    [wCost]       NUMERIC (18, 2) NOT NULL,
    [wCurrCode]   VARCHAR (6)     NOT NULL,
    [wSeqNo]      INT             NOT NULL,
    [wCrtDt]      DATETIME2 (7)   NOT NULL,
    [wCrtBy]      BIGINT          NOT NULL,
    [wUpdDt]      DATETIME2 (7)   NOT NULL,
    [wUpdBy]      BIGINT          NOT NULL,
    CONSTRAINT [PK__mShowTic__FFEE745138ACFA11] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



