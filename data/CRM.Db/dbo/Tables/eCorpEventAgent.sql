CREATE TABLE [dbo].[eCorpEventAgent] (
    [RowID]           BIGINT         NOT NULL,
    [wCorpEventRid]   BIGINT         NOT NULL,
    [wAgentCodeIn]    VARCHAR (14)   NOT NULL,
    [wResponseType]   VARCHAR (30)   NOT NULL,
    [wGuestInvited]   INT            CONSTRAINT [DF_eCorpEventAgent_wGuestInvited] DEFAULT ((0)) NOT NULL,
    [wGuestAttend]    INT            CONSTRAINT [DF_eCorpEventAgent_wGuestAttend] DEFAULT ((0)) NOT NULL,
    [wRemark]         NVARCHAR (500) CONSTRAINT [DF_eCorpEventAgent_wRemark] DEFAULT (N'') NOT NULL,
    [wStatus]         CHAR (1)       CONSTRAINT [DF_eCorpEventAgent_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]          DATETIME2 (7)  NOT NULL,
    [wCrtBy]          BIGINT         NOT NULL,
    [wUpdDt]          DATETIME2 (7)  NOT NULL,
    [wUpdBy]          BIGINT         NOT NULL,
    [wCfmGuestAttend] INT            NULL,
    CONSTRAINT [PK_eCorpEventAgent_1] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






GO


