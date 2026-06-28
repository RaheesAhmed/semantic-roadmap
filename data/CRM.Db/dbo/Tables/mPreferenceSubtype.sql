CREATE TABLE [dbo].[mPreferenceSubtype] (
    [RowID]              BIGINT        NOT NULL,
    [wPreferenceTypeRid] BIGINT        NOT NULL,
    [wName]              NVARCHAR (50) NOT NULL,
    [wCode]              VARCHAR (10)  NOT NULL,
    [wStatus]            VARCHAR (1)   NOT NULL,
    [wSeqNo]             INT           NOT NULL,
    [wCrtDt]             DATETIME2 (7) NOT NULL,
    [wCrtBy]             BIGINT        NOT NULL,
    [wUpdDt]             DATETIME2 (7) NOT NULL,
    [wUpdBy]             BIGINT        NOT NULL,
    CONSTRAINT [PK_mPreferenceSubtype] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

