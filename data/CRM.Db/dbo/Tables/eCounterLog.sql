CREATE TABLE [dbo].[eCounterLog] (
    [RowID]              BIGINT          NOT NULL,
    [wCompNo]            INT             CONSTRAINT [DF_eCounterLog_wCompNo] DEFAULT ((0)) NOT NULL,
    [wDeptCd]            VARCHAR (30)    NOT NULL,
    [wUserRid]           BIGINT          NOT NULL,
    [wType]              NVARCHAR (50)   NOT NULL,
    [wRelateAgentCodeIn] VARCHAR (14)    NOT NULL,
    [wRelatePersonRid]   BIGINT          NULL,
    [wTitle]             NVARCHAR (500)  NOT NULL,
    [wContent]           NVARCHAR (4000) NULL,
    [wDateTime]          DATETIME        NOT NULL,
    [wIsImportant]       CHAR (1)        CONSTRAINT [DF__eCounterL__wIsIm__0A000E0B] DEFAULT ('N') NOT NULL,
    [wIsProcessed]       VARCHAR (2)     CONSTRAINT [DF__eCounterL__wIsPr__0AF43244] DEFAULT ('N') NOT NULL,
    [wIsClosed]          VARCHAR (1)     DEFAULT ('N') NULL,
    [wStatus]            CHAR (1)        CONSTRAINT [DF__eCounterL__wStat__0BE8567D] DEFAULT ('A') NULL,
    [wCrtDt]             DATETIME2 (7)   CONSTRAINT [DF__eCounterL__wCrtD__0CDC7AB6] DEFAULT (getdate()) NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   CONSTRAINT [DF__eCounterL__wUpdD__0DD09EEF] DEFAULT (getdate()) NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wCounterRid]        BIGINT          CONSTRAINT [DF_eCounterLog_wCounterRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__eCounter__FFEE7451AB14BFBF] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO



GO



GO



GO



GO



GO



GO



GO



GO



GO



GO



GO


