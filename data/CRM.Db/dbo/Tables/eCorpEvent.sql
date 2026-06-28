CREATE TABLE [dbo].[eCorpEvent] (
    [RowID]           BIGINT         NOT NULL,
    [wName]           NVARCHAR (100) CONSTRAINT [DF_eCorpEvent_wName] DEFAULT ('') NOT NULL,
    [wCategory]       VARCHAR (30)   NOT NULL,
    [wSubCategory]    VARCHAR (30)   CONSTRAINT [DF_eCorpEvent_wSubCategory] DEFAULT ('') NOT NULL,
    [wStartDt]        DATETIME2 (7)  CONSTRAINT [DF_eCorpEvent_wStartDt] DEFAULT ([dbo].[fnUTC8Now]()) NOT NULL,
    [wEndDt]          DATETIME2 (7)  CONSTRAINT [DF_eCorpEvent_wEndDt] DEFAULT ([dbo].[fnUTC8Now]()) NOT NULL,
    [wIsCharged]      CHAR (1)       CONSTRAINT [DF_eCorpEvent_wIsCharged] DEFAULT ('"N''') NOT NULL,
    [wRemark]         NVARCHAR (500) CONSTRAINT [DF_eCorpEvent_wRemark] DEFAULT (N'') NOT NULL,
    [wGuestInvited]   INT            CONSTRAINT [DF_eCorpEvent_wGuestInvited] DEFAULT ((0)) NOT NULL,
    [wGuestAttend]    INT            CONSTRAINT [DF_eCorpEvent_wGuestAttend] DEFAULT ((0)) NOT NULL,
    [wStatus]         CHAR (1)       CONSTRAINT [DF_eCorpEvent_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]          DATETIME2 (7)  NOT NULL,
    [wCrtBy]          BIGINT         NOT NULL,
    [wUpdDt]          DATETIME2 (7)  NOT NULL,
    [wUpdBy]          BIGINT         NOT NULL,
    [wCfmGuestAttend] INT            NULL,
    CONSTRAINT [PK_eCorpEvent] PRIMARY KEY CLUSTERED ([RowID] ASC)
);



