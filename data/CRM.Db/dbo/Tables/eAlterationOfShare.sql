CREATE TABLE [dbo].[eAlterationOfShare] (
    [RowID]                  BIGINT          NOT NULL,
    [wDate]                  DATE            NOT NULL,
    [wAgentCodeIn]           VARCHAR (14)    NOT NULL,
    [wRegionCode]            VARCHAR (3)     NOT NULL,
    [wReasonOfAlteration]    NVARCHAR (500)  NOT NULL,
    [wActionCode]            VARCHAR (4)     NOT NULL,
    [wCurrCode]              VARCHAR (6)     NOT NULL,
    [wNumberOfSharesChanged] NUMERIC (18, 2) NOT NULL,
    [wCurrentShares]         NUMERIC (18, 2) NOT NULL,
    [wStatus]                CHAR (1)        NOT NULL,
    [wCrtDt]                 DATETIME2 (7)   NOT NULL,
    [wCrtBy]                 BIGINT          NOT NULL,
    [wUpdDt]                 DATETIME2 (7)   NOT NULL,
    [wUpdBy]                 BIGINT          NOT NULL,
    [wHandler]               BIGINT          NOT NULL,
    CONSTRAINT [PK_eAlterationOfShare] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

