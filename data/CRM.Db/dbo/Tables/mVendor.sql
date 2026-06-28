CREATE TABLE [dbo].[mVendor] (
    [RowID]        BIGINT         NOT NULL,
    [wCName]       NVARCHAR (100) NOT NULL,
    [wEName]       VARCHAR (100)  NOT NULL,
    [wAddress]     NVARCHAR (500) NOT NULL,
    [wTel]         VARCHAR (100)  NOT NULL,
    [wGracePeriod] INT            NOT NULL,
    [wStatus]      CHAR (1)       CONSTRAINT [DF_mVendor_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]       DATETIME2 (7)  NOT NULL,
    [wUpdDt]       DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_mVendor] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

