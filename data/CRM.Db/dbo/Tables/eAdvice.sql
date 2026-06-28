CREATE TABLE [dbo].[eAdvice] (
    [RowID]           BIGINT          NOT NULL,
    [wAim]            NVARCHAR (200)  NOT NULL,
    [wDate]           DATE            NOT NULL,
    [wAgentCodeIn]    VARCHAR (14)    NOT NULL,
    [wReceivedBy]     BIGINT          NOT NULL,
    [wReceivedDeptCd] VARCHAR (30)    NOT NULL,
    [wType]           VARCHAR (30)    NOT NULL,
    [wSubType]        VARCHAR (30)    NOT NULL,
    [wAdviceStatus]   VARCHAR (20)    NOT NULL,
    [wContent]        NVARCHAR (2000) NOT NULL,
    [wStatus]         CHAR (1)        CONSTRAINT [DF_eAdvice_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]          DATETIME2 (7)   NOT NULL,
    [wCrtBy]          BIGINT          NOT NULL,
    [wUpdDt]          DATETIME2 (7)   NOT NULL,
    [wUpdBy]          BIGINT          NOT NULL,
    [wIsHighPriority] CHAR (1)        CONSTRAINT [DF_eAdvice_wIsHighPirority] DEFAULT ('N') NOT NULL,
    [wRefNo]          VARCHAR (30)    CONSTRAINT [DF_eAdvice_wRefNo] DEFAULT ('') NOT NULL,
    [wDealDt]         DATETIME2 (7)   CONSTRAINT [DF__eAdvice__wDealDt__7D260131] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_eAdvice] PRIMARY KEY CLUSTERED ([RowID] ASC)
);










GO
CREATE NONCLUSTERED INDEX [PI_eAdvice_01]
    ON [dbo].[eAdvice]([wAgentCodeIn] ASC);

