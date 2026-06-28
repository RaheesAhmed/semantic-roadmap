CREATE TABLE [dbo].[mTicketCollectionPoint] (
    [RowID]             BIGINT         NOT NULL,
    [wCode]             VARCHAR (50)   NOT NULL,
    [wName]             NVARCHAR (50)  NOT NULL,
    [wIsFerryTic]       CHAR (1)       NOT NULL,
    [wIsAirTic]         CHAR (1)       NOT NULL,
    [wIsCheckInService] CHAR (1)       NOT NULL,
    [wIsShowTic]        CHAR (1)       NOT NULL,
    [wSeqNo]            INT            NOT NULL,
    [wStatus]           CHAR (1)       CONSTRAINT [DF_mTicketCollectionPoint_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]            DATETIME2 (7)  NOT NULL,
    [wCrtBy]            BIGINT         NOT NULL,
    [wUpdDt]            DATETIME2 (7)  NOT NULL,
    [wUpdBy]            BIGINT         NOT NULL,
    [wIsVisa]           CHAR (1)       CONSTRAINT [DF__mTicketCo__wIsVi__7A9D0393] DEFAULT ('N') NOT NULL,
    [wAddress]          NVARCHAR (500) NULL,
    CONSTRAINT [PK_mTicketCollectionPoint] PRIMARY KEY CLUSTERED ([RowID] ASC)
);









