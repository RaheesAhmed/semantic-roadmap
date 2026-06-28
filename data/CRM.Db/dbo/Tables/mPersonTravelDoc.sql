CREATE TABLE [dbo].[mPersonTravelDoc] (
    [RowID]          BIGINT         NOT NULL,
    [wPersonRID]     BIGINT         NOT NULL,
    [wIDType]        VARCHAR (30)   NOT NULL,
    [wIDNo]          VARCHAR (30)   NOT NULL,
    [wIssueAt]       VARCHAR (20)   NULL,
    [wExpiryDate]    DATE           NULL,
    [wRemark]        NVARCHAR (100) NULL,
    [wStatus]        CHAR (1)       NOT NULL,
    [wCrtDt]         DATETIME2 (7)  NOT NULL,
    [wCrtBy]         BIGINT         NOT NULL,
    [wUpdDt]         DATETIME2 (7)  NOT NULL,
    [wUpdBy]         BIGINT         NOT NULL,
    [wRefRID]        BIGINT         DEFAULT ((-1)) NOT NULL,
    [wEnglishPinyin] NVARCHAR (100) CONSTRAINT [DF_mPersonTravelDoc_wEnglishPinyin] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_mPersonTravelDoc] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO
CREATE NONCLUSTERED INDEX [PI_mPersonTravelDoc_01]
    ON [dbo].[mPersonTravelDoc]([wPersonRID] ASC);

