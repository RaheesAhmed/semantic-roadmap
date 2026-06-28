CREATE TABLE [dbo].[mServiceCounter] (
    [RowID]              BIGINT          NOT NULL,
    [wCode]              NVARCHAR (50)   NOT NULL,
    [wName]              NVARCHAR (20)   NOT NULL,
    [wSmsRoomID]         INT             NULL,
    [wRollexCompNo]      INT             NOT NULL,
    [wRegion]            VARCHAR (20)    NOT NULL,
    [wDefaultHotelCode]  NVARCHAR (20)   NULL,
    [wCurrCode]          VARCHAR (6)     NOT NULL,
    [wRemark]            NVARCHAR (500)  CONSTRAINT [DF_mServiceCounter_wRemark] DEFAULT ('') NULL,
    [wStatus]            CHAR (1)        CONSTRAINT [DF_mServiceCounter_wStatus] DEFAULT ('A') NOT NULL,
    [wSeqNo]             INT             CONSTRAINT [DF_mServiceCounter_wSeqNo] DEFAULT ((1)) NOT NULL,
    [wCrtDt]             DATETIME2 (7)   NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wSMSName]           NVARCHAR (50)   CONSTRAINT [DF_mServiceCounter_wSMSName] DEFAULT ('') NOT NULL,
    [wCollectionPointCd] VARCHAR (30)    CONSTRAINT [DF_mServiceCounter_wCollectionPointRid] DEFAULT ('') NOT NULL,
    [wStoreAgentCodeIn]  VARCHAR (14)    CONSTRAINT [DF_mServiceCounter_wStoreAgentCodeIn] DEFAULT ('') NOT NULL,
    [wHandlingFee]       NUMERIC (18, 4) CONSTRAINT [DF_mServiceCounter_wHandlingFee] DEFAULT ((0)) NOT NULL,
    [wAddress]           NVARCHAR (500)  NULL,
    [wTransferSMSName]   NVARCHAR (50)   DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_mServiceCounter] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






















GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'轉賬SMS名稱', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'mServiceCounter', @level2type = N'COLUMN', @level2name = N'wTransferSMSName';

