CREATE TABLE [dbo].[eTaskSheet] (
    [RowID]              BIGINT          NOT NULL,
    [wCompNo]            INT             NOT NULL,
    [wDeptCd]            VARCHAR (30)    NOT NULL,
    [wDate]              DATE            NOT NULL,
    [wTaskType]          VARCHAR (30)    NOT NULL,
    [wSubTaskType]       VARCHAR (30)    NOT NULL,
    [wIsInhouse]         CHAR (1)        CONSTRAINT [DF_eTaskSheet_wIsInhouse] DEFAULT ('Y') NOT NULL,
    [wContent]           NVARCHAR (4000) CONSTRAINT [DF_eTaskSheet_wContent] DEFAULT ('') NOT NULL,
    [wRemark]            NVARCHAR (500)  CONSTRAINT [DF_eTaskSheet_wRemark] DEFAULT ('') NOT NULL,
    [wRelateAgentCodeIn] VARCHAR (14)    CONSTRAINT [DF_eTaskSheet_wRelateAgentCodeIn] DEFAULT ('') NOT NULL,
    [wRelatedType]       VARCHAR (30)    CONSTRAINT [DF_Table_1_wRelateBookingRefNo] DEFAULT ('') NOT NULL,
    [wRelatedRid]        BIGINT          CONSTRAINT [DF_Table_1_wRelateContactRefNo] DEFAULT ((-1)) NULL,
    [wHasDoc]            CHAR (1)        CONSTRAINT [DF_eTaskSheet_wHasDoc] DEFAULT ('N') NOT NULL,
    [wStatus]            CHAR (1)        CONSTRAINT [DF_eTaskSheet_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]             DATETIME2 (7)   NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wFollowUpDt]        DATETIME2 (7)   CONSTRAINT [DF_eTaskSheet_wFollowedDt] DEFAULT ('1900-01-01') NOT NULL,
    [wFollowUpBy]        BIGINT          CONSTRAINT [DF_eTaskSheet_wFollowedBy] DEFAULT ((0)) NOT NULL,
    [wUsrRid]            BIGINT          CONSTRAINT [DF_eTaskSheet_wUsrRid] DEFAULT ((0)) NOT NULL,
    [wTaskSheetStatus]   VARCHAR (30)    CONSTRAINT [DF_eTaskSheet_wTaskSheetStatus] DEFAULT ('') NOT NULL,
    [wCounterRid]        BIGINT          CONSTRAINT [DF_eTaskSheet_wCounterRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eTaskSheet] PRIMARY KEY CLUSTERED ([RowID] ASC)
);


















GO



GO



GO



GO



GO



GO



GO



GO



GO



GO



GO
CREATE NONCLUSTERED INDEX [PI_eTaskSheet_01]
    ON [dbo].[eTaskSheet]([wRelatedType] ASC, [wRelatedRid] ASC, [wStatus] ASC);

