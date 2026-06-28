CREATE TABLE [dbo].[mPerson] (
    [RowID]         BIGINT         NOT NULL,
    [wAgentCodeIn]  VARCHAR (14)   NOT NULL,
    [wCName]        NVARCHAR (50)  CONSTRAINT [DF_mPerson_wCName] DEFAULT ('') NOT NULL,
    [wEName]        VARCHAR (500)  CONSTRAINT [DF_mPerson_wEName] DEFAULT ('') NOT NULL,
    [wNickname]     NVARCHAR (50)  CONSTRAINT [DF_mPerson_wNickname] DEFAULT ('') NOT NULL,
    [wRole]         VARCHAR (10)   NOT NULL,
    [wSpeakLangCd]  VARCHAR (10)   NOT NULL,
    [wWritenLangCd] VARCHAR (10)   NOT NULL,
    [wGender]       CHAR (1)       CONSTRAINT [DF_mPerson_wGender] DEFAULT ('M') NOT NULL,
    [wBirthdate]    DATE           NULL,
    [wNationality]  VARCHAR (30)   NOT NULL,
    [wProvince]     NVARCHAR (50)  CONSTRAINT [DF_mPerson_wProvince] DEFAULT ('') NOT NULL,
    [wAddress]      NVARCHAR (500) NOT NULL,
    [wTelBusiness]  VARCHAR (50)   CONSTRAINT [DF_mPerson_wTelBusiness] DEFAULT ('') NOT NULL,
    [wTelHome]      VARCHAR (50)   CONSTRAINT [DF_mPerson_wTelHome] DEFAULT ('') NOT NULL,
    [wTelOther]     VARCHAR (100)  CONSTRAINT [DF_mPerson_wTelOther] DEFAULT ('') NOT NULL,
    [wRefRID]       BIGINT         NULL,
    [wStatus]       CHAR (1)       NOT NULL,
    [wCrtDt]        DATETIME2 (7)  NOT NULL,
    [wCrtBy]        BIGINT         NOT NULL,
    [wUpdDt]        DATETIME2 (7)  NOT NULL,
    [wUpdBy]        BIGINT         NOT NULL,
    CONSTRAINT [PK_mPerson] PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO



GO



GO
CREATE NONCLUSTERED INDEX [PI_mPerson_01]
    ON [dbo].[mPerson]([wAgentCodeIn] ASC, [wStatus] ASC);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'OWNER/AUTH/CLIENT', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mPerson', @level2type = N'COLUMN', @level2name = N'wRole';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'[F]Rollsmary.dbo.mAgent.wAgentCodeIn', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mPerson', @level2type = N'COLUMN', @level2name = N'wAgentCodeIn';

