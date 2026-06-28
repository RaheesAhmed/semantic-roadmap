CREATE TABLE [dbo].[mPersonPerference] (
    [RowID]              BIGINT         NOT NULL,
    [wPersonRid]         BIGINT         NOT NULL,
    [wPerferenceType]    VARCHAR (30)   NOT NULL,
    [wPerferenceSubType] VARCHAR (30)   NOT NULL,
    [wRemark]            NVARCHAR (500) NOT NULL,
    [wSeqNo]             INT            NOT NULL,
    [wCrtDt]             DATETIME2 (7)  NOT NULL,
    [wCrtBy]             BIGINT         NOT NULL,
    [wUpdDt]             DATETIME2 (7)  NOT NULL,
    [wUpdBy]             BIGINT         NOT NULL,
    CONSTRAINT [PK_mPersonPerference] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

