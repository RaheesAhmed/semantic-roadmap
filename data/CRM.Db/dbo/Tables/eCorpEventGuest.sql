CREATE TABLE [dbo].[eCorpEventGuest] (
    [RowID]           BIGINT         NOT NULL,
    [wCorpEventRid]   BIGINT         NOT NULL,
    [wAgentCodeIn]    VARCHAR (14)   NOT NULL,
    [wGuestName]      NVARCHAR (50)  NOT NULL,
    [wPersonRid]      BIGINT         CONSTRAINT [DF_eCorpEventGuest_wPersonRid] DEFAULT ((-1)) NOT NULL,
    [wGuestInvited]   INT            CONSTRAINT [DF_eCorpEventGuest_wGuestInvited] DEFAULT ((0)) NOT NULL,
    [wGuestAttend]    INT            CONSTRAINT [DF_eCorpEventGuest_wGuestAttend] DEFAULT ((0)) NOT NULL,
    [wRemark]         NVARCHAR (500) CONSTRAINT [DF_eCorpEventGuest_wRemark] DEFAULT (N'') NOT NULL,
    [wStatus]         CHAR (1)       CONSTRAINT [DF_eCorpEventGuest_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]          DATETIME2 (7)  NOT NULL,
    [wCrtBy]          BIGINT         NOT NULL,
    [wUpdDt]          DATETIME2 (7)  NOT NULL,
    [wUpdBy]          BIGINT         NOT NULL,
    [wCfmGuestAttend] INT            NULL,
    CONSTRAINT [PK_eCorpEventGuest] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






GO


