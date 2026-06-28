CREATE TABLE [dbo].[eServiceCounterLog] (
    [wCode]      NVARCHAR (50) NOT NULL,
    [wDateTime]  DATETIME2 (7) NULL,
    [wStatus]    CHAR (1)      NOT NULL,
    [wCrtDt]     DATETIME2 (7) NOT NULL,
    [wCrtBy]     BIGINT        NOT NULL,
    [wUpdDt]     DATETIME2 (7) NOT NULL,
    [wUpdBy]     BIGINT        NOT NULL,
    [RowId]      BIGINT        NOT NULL,
    [wConterRid] BIGINT        DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([RowId] ASC)
);



