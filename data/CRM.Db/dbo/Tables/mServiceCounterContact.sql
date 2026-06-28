CREATE TABLE [dbo].[mServiceCounterContact] (
    [RowID]              BIGINT        NOT NULL,
    [wSeriverCounterRid] BIGINT        NOT NULL,
    [wDepartmentCode]    VARCHAR (30)  NOT NULL,
    [wContactType]       VARCHAR (10)  NOT NULL,
    [wTel]               VARCHAR (30)  NOT NULL,
    [wEmail]             VARCHAR (100) NOT NULL,
    [wIsUsingApp]        CHAR (1)      CONSTRAINT [DF_mServiceCounterContact_wIsUsingApp] DEFAULT ('Y') NOT NULL,
    [wSeqNo]             INT           CONSTRAINT [DF_mServiceCounterContact_wSeqNo] DEFAULT ((1)) NOT NULL,
    [wCrtDt]             DATETIME2 (7) NOT NULL,
    [wCrtBy]             BIGINT        NOT NULL,
    [wUpdDt]             DATETIME2 (7) NOT NULL,
    [wUpdBy]             BIGINT        NOT NULL,
    CONSTRAINT [PK_mServiceCounterContact] PRIMARY KEY CLUSTERED ([RowID] ASC),
    CONSTRAINT [FK_mServiceCounterContact_mServiceCounter] FOREIGN KEY ([wSeriverCounterRid]) REFERENCES [dbo].[mServiceCounter] ([RowID])
);




GO


