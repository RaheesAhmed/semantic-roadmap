CREATE TABLE [dbo].[mPersonRelationship] (
    [RowID]            BIGINT         NOT NULL,
    [wPersonRid]       BIGINT         NOT NULL,
    [wRelatePersonRid] BIGINT         NOT NULL,
    [wRelationType]    VARCHAR (30)   NOT NULL,
    [wRemark]          NVARCHAR (500) NOT NULL,
    [wSeqNo]           INT            NOT NULL,
    [wCrtDt]           DATETIME2 (7)  NOT NULL,
    [wCrtBy]           BIGINT         NOT NULL,
    [wUpdDt]           DATETIME2 (7)  NOT NULL,
    [wUpdBy]           BIGINT         NOT NULL,
    [wStatus]          CHAR (1)       DEFAULT ('A') NOT NULL,
    CONSTRAINT [PK_mPersonRelationship] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



