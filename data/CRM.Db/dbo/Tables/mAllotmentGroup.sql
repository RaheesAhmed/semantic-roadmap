CREATE TABLE [dbo].[mAllotmentGroup] (
    [RowID]   BIGINT         NOT NULL,
    [wCode]   VARCHAR (30)   NOT NULL,
    [wName]   NVARCHAR (50)  NOT NULL,
    [wRemark] NVARCHAR (500) NOT NULL,
    [wStatus] CHAR (1)       NOT NULL,
    [wSeqNo]  INT            NOT NULL,
    [wCrtDt]  DATETIME2 (7)  NOT NULL,
    [wCrtBy]  BIGINT         NOT NULL,
    [wUpdDt]  DATETIME2 (7)  NOT NULL,
    [wUpdBy]  BIGINT         NOT NULL,
    [wDept]   NVARCHAR (20)  NULL,
    CONSTRAINT [PK_wAllotmentGroup] PRIMARY KEY CLUSTERED ([RowID] ASC)
);





