CREATE TABLE [dbo].[mCustomQueryTargetGroup] (
    [RowID]             BIGINT        NOT NULL,
    [wCustomQueryRid]   BIGINT        NOT NULL,
    [wTargetGroupTable] VARCHAR (50)  NOT NULL,
    [wTargetGroupRid]   BIGINT        NOT NULL,
    [wIsDefault]        CHAR (1)      CONSTRAINT [DF_mCustomQueryTargetGroup_wIsDefault] DEFAULT ('N') NOT NULL,
    [wCrtBy]            BIGINT        NOT NULL,
    [wCrtDt]            DATETIME2 (7) NOT NULL,
    [wUpdBy]            BIGINT        NOT NULL,
    [wUpdDt]            DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_mCustomQueryTargetGroup] PRIMARY KEY CLUSTERED ([RowID] ASC)
);







