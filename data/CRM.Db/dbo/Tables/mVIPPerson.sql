CREATE TABLE [dbo].[mVIPPerson] (
    [RowID]                  BIGINT          NOT NULL,
    [wAgentCodeIn]           VARCHAR (14)    NOT NULL,
    [wPersonName]            NVARCHAR (50)   NOT NULL,
    [wPersonIdentity]        VARCHAR (30)    NOT NULL,
    [wGender]                VARCHAR (5)     NOT NULL,
    [wAuthorizerAgentCodeIn] VARCHAR (14)    NULL,
    [wAuthorizerIdentity]    VARCHAR (30)    NULL,
    [wRelationship]          VARCHAR (30)    NULL,
    [wOtherRelationship]     NVARCHAR (200)  NULL,
    [wBirthDate]             DATE            NOT NULL,
    [wCalendarType]          CHAR (5)        NOT NULL,
    [wYear]                  INT             NOT NULL,
    [wMonth]                 INT             NOT NULL,
    [wDay]                   INT             NOT NULL,
    [wIsLeapMonth]           CHAR (1)        CONSTRAINT [DF__mVIPPerso__wIsLe__5CD92D30] DEFAULT ('N') NOT NULL,
    [wContactWay]            VARCHAR (30)    NULL,
    [wTelNumber]             NVARCHAR (150)  NULL,
    [wWhatsappNumber]        NVARCHAR (100)  NULL,
    [wWeChatNumber]          NVARCHAR (100)  NULL,
    [wWeChatName]            NVARCHAR (100)  NULL,
    [wBudgetRatio]           NUMERIC (18, 4) NULL,
    [wIsWeChatVerify]        CHAR (1)        CONSTRAINT [DF__mVIPPerso__wIsWe__5EC175A2] DEFAULT ('N') NOT NULL,
    [wIsPresentGift]         CHAR (1)        CONSTRAINT [DF__mVIPPerso__wIsPr__5FB599DB] DEFAULT ('Y') NOT NULL,
    [wIsAuthorizer]          CHAR (1)        CONSTRAINT [DF__mVIPPerso__wIsAu__60A9BE14] DEFAULT ('N') NOT NULL,
    [wStatus]                CHAR (1)        NOT NULL,
    [wCrtBy]                 BIGINT          NOT NULL,
    [wCrtDt]                 DATETIME2 (7)   NOT NULL,
    [wUpdBy]                 BIGINT          NOT NULL,
    [wUpdDt]                 DATETIME2 (7)   NOT NULL,
    [wStatusRemark]          NVARCHAR (4000) NULL,
    [wSource]                VARCHAR (10)    CONSTRAINT [DF__mVIPPerso__wSour__0C1E2BFE] DEFAULT ('001') NOT NULL,
    [wIsRefusedContact]      CHAR (1)        CONSTRAINT [DF__mVIPPerso__wIsRe__1E3CDC39] DEFAULT ('N') NOT NULL,
    [wVIPPersonStatus]       CHAR (1)        CONSTRAINT [DF__mVIPPerso__wVIPP__37088A03] DEFAULT ('A') NOT NULL,
    CONSTRAINT [PK__mVIPPers__FFEE7451B1DD8155] PRIMARY KEY CLUSTERED ([RowID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_wAuthorizerAgentCodeIn]
    ON [dbo].[mVIPPerson]([wAuthorizerAgentCodeIn] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_wAgentCodeIn]
    ON [dbo].[mVIPPerson]([wAgentCodeIn] ASC);

