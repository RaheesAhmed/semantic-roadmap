CREATE TABLE [dbo].[ePointsTradingRemarks] (
    [RowID]             BIGINT         NOT NULL,
    [wPointsTradingRid] BIGINT         NOT NULL,
    [wRemarks]          NVARCHAR (200) NOT NULL,
    [wStatus]           CHAR (1)       NOT NULL,
    [wCrtBy]            BIGINT         NOT NULL,
    [wCrtDt]            DATETIME2 (7)  NOT NULL,
    [wUpdDt]            DATETIME2 (7)  NOT NULL,
    [wUpdBy]            BIGINT         NOT NULL,
    CONSTRAINT [PK_ePointsTradingRemark] PRIMARY KEY CLUSTERED ([RowID] ASC)
);

