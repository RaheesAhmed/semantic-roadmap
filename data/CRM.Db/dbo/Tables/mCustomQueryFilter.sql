CREATE TABLE [dbo].[mCustomQueryFilter] (
    [RowID]           BIGINT        NOT NULL,
    [wCustomQueryRid] BIGINT        NOT NULL,
    [wFilterCode]     VARCHAR (50)  NOT NULL,
    [wIsVisible]      CHAR (1)      NOT NULL,
    [wDefaultValue]   VARCHAR (50)  CONSTRAINT [DF_mCustomQueryFilter_wDefaultValue] DEFAULT ('DEFAULT') NOT NULL,
    [wStatus]         CHAR (1)      CONSTRAINT [DF_mCustomQueryFilter_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtBy]          BIGINT        NOT NULL,
    [wCrtDt]          NCHAR (10)    NOT NULL,
    [wUpdBy]          BIGINT        NOT NULL,
    [wUpdDt]          DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_mCustomQueryFilter] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

