CREATE TABLE [dbo].[mAirport] (
    [RowID]   BIGINT         NOT NULL,
    [wCName]  NVARCHAR (50)  NOT NULL,
    [wCode]   NVARCHAR (10)  NOT NULL,
    [wCity]   VARCHAR (10)   NOT NULL,
    [wRemark] NVARCHAR (500) CONSTRAINT [DF_mAirport_wRemark] DEFAULT (N'') NOT NULL,
    [wSeqNo]  INT            NOT NULL,
    [wCrtDt]  DATETIME2 (7)  NOT NULL,
    [wCrtBy]  BIGINT         NOT NULL,
    [wUpdDt]  DATETIME2 (7)  NOT NULL,
    [wUpdBy]  BIGINT         NOT NULL,
    [wStatus] CHAR (1)       CONSTRAINT [DF_mAirport_wStatus] DEFAULT ('A') NOT NULL,
    [wEName]  VARCHAR (200)  NULL,
    CONSTRAINT [PK_mAirport] PRIMARY KEY CLUSTERED ([RowID] ASC)
);








GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Refer to LookUp.CITY', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mAirport', @level2type = N'COLUMN', @level2name = N'wCity';

