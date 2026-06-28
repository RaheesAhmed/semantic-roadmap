CREATE TABLE [dbo].[mCustomQuery] (
    [RowID]          BIGINT        NOT NULL,
    [wQueryCd]       VARCHAR (50)  NOT NULL,
    [wQueryName]     NVARCHAR (50) CONSTRAINT [DF_mCustomQuery_wQueryName] DEFAULT ('') NOT NULL,
    [wStatus]        CHAR (1)      CONSTRAINT [DF_mCustomQuery_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtBy]         BIGINT        NOT NULL,
    [wCrtDt]         DATETIME2 (7) NOT NULL,
    [wUpdBy]         BIGINT        NOT NULL,
    [wUpdDt]         DATETIME2 (7) NOT NULL,
    [wQueryCategory] VARCHAR (30)  CONSTRAINT [DF_mCustomQuery_wType] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_mCustomQuery] PRIMARY KEY CLUSTERED ([RowID] ASC)
);





