CREATE TABLE [dbo].[eActivityLog] (
    [RowID]           BIGINT         NOT NULL,
    [wAction]         VARCHAR (10)   NOT NULL,
    [wReqAgentCodeIn] VARCHAR (14)   NOT NULL,
    [wBookingRid]     BIGINT         NOT NULL,
    [wCategory]       VARCHAR (30)   NOT NULL,
    [wRemark]         NVARCHAR (500) NOT NULL,
    [wIsLatest]       CHAR (1)       CONSTRAINT [DF_eActivityLog_wIsLastest] DEFAULT ('Y') NOT NULL,
    [wIsComplete]     CHAR (1)       CONSTRAINT [DF_eActivityLog_wIsCompelete] DEFAULT ('N') NOT NULL,
    [wCrtDt]          DATETIME2 (7)  NOT NULL,
    [wCrtBy]          BIGINT         NOT NULL,
    [wUpdDt]          DATETIME2 (7)  NOT NULL,
    [wUpdBy]          BIGINT         NOT NULL,
    CONSTRAINT [PK_eActivityLog] PRIMARY KEY CLUSTERED ([RowID] ASC)
);





