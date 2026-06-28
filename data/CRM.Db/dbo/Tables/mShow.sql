CREATE TABLE [dbo].[mShow] (
    [RowID]            BIGINT         NOT NULL,
    [wName]            NVARCHAR (50)  NOT NULL,
    [wVenue]           NVARCHAR (50)  NOT NULL,
    [wStartDate]       DATE           NOT NULL,
    [wEndDate]         DATE           NOT NULL,
    [wShowCatCode]     VARCHAR (10)   NOT NULL,
    [wIsExtraName]     CHAR (1)       NOT NULL,
    [wPerformanceArea] NVARCHAR (100) CONSTRAINT [DF_mShow_wPerformanceArea_1] DEFAULT ('') NOT NULL,
    [wIsFullDay]       CHAR (1)       NOT NULL,
    [wContent]         NVARCHAR (500) NOT NULL,
    [wPerformanceDt]   DATETIME2 (7)  NOT NULL,
    [wStatus]          CHAR (1)       NOT NULL,
    [wSeqNo]           INT            NOT NULL,
    [wCrtDt]           DATETIME2 (7)  NOT NULL,
    [wCrtBy]           BIGINT         NOT NULL,
    [wUpdDt]           DATETIME2 (7)  NOT NULL,
    [wUpdBy]           BIGINT         NOT NULL,
    [wSupplier]        BIGINT         CONSTRAINT [DF_mShow_wSupplier_1] DEFAULT ((-1)) NOT NULL,
    [wHaveTicket]      CHAR (1)       CONSTRAINT [DF_mShow_wHaveTicket] DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_mShow] PRIMARY KEY CLUSTERED ([RowID] ASC)
);









