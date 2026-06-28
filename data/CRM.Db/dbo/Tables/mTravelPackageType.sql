CREATE TABLE [dbo].[mTravelPackageType] (
    [RowID]      BIGINT        NOT NULL,
    [wCode]      NVARCHAR (30) NOT NULL,
    [wName]      NVARCHAR (50) NOT NULL,
    [wValidDate] DATETIME2 (7) NOT NULL,
    [wStatus]    CHAR (1)      NOT NULL,
    [wCrtDt]     DATETIME2 (7) NOT NULL,
    [wCrtBy]     BIGINT        NOT NULL,
    [wUpdDt]     DATETIME2 (7) NOT NULL,
    [wUpdBy]     BIGINT        NOT NULL,
    CONSTRAINT [PK_mTravelPackageType] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

