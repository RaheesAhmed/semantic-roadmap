CREATE TABLE [dbo].[mProcess] (
    [RowID]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [wScopeType]         VARCHAR (30)  NOT NULL,
    [wProcessType]       VARCHAR (30)  NOT NULL,
    [wCurrectStepValue]  VARCHAR (30)  NOT NULL,
    [wPreviousStepValue] VARCHAR (30)  NOT NULL,
    [wStatus]            VARCHAR (1)   CONSTRAINT [DF_mProcess_wStatus] DEFAULT ('A') NOT NULL,
    [wUpdDt]             DATETIME2 (7) NOT NULL,
    [wCrtDt]             DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_mProcess] PRIMARY KEY CLUSTERED ([RowID] ASC)
);




GO



GO


