CREATE TABLE [dbo].[mCustomQueryColumn] (
    [RowID]           BIGINT        NOT NULL,
    [wCustomQueryRid] BIGINT        NOT NULL,
    [wColumnCode]     VARCHAR (50)  NOT NULL,
    [wIsVisible]      CHAR (1)      NOT NULL,
    [wAllowSelect]    CHAR (1)      CONSTRAINT [DF_mCustomQueryColumn_wAllowSelect] DEFAULT ('Y') NOT NULL,
    [wAllowSortAcsc]  CHAR (1)      NOT NULL,
    [wAllowSortDesc]  CHAR (1)      NOT NULL,
    [wStatus]         CHAR (1)      CONSTRAINT [DF_mCustomQueryColumn_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtBy]          BIGINT        NOT NULL,
    [wCrtDt]          DATETIME2 (7) NOT NULL,
    [wUpdBy]          BIGINT        NOT NULL,
    [wUpdDt]          DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_mCustomQueryColumn] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

