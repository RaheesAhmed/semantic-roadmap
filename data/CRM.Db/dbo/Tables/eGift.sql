CREATE TABLE [dbo].[eGift] (
    [RowID]                 BIGINT          NOT NULL,
    [wRefBookingRid]        BIGINT          CONSTRAINT [DF_eGift_wRefBookingRid] DEFAULT ((-1)) NOT NULL,
    [wRefTableName]         VARCHAR (50)    CONSTRAINT [DF_eGift_wRefTableName] DEFAULT ('') NOT NULL,
    [wRefTableRid]          BIGINT          CONSTRAINT [DF_eGift_wRefStockSalesDtlRid] DEFAULT ((-1)) NOT NULL,
    [wOriActionType]        VARCHAR (50)    CONSTRAINT [DF_eGift_wOriActionType] DEFAULT ('') NOT NULL,
    [wReqCounterRid]        BIGINT          NOT NULL,
    [wCompNo]               INT             CONSTRAINT [DF_eGift_wCompNo] DEFAULT ((0)) NOT NULL,
    [wCageCodeIn]           VARCHAR (14)    NOT NULL,
    [wReqDeptCd]            VARCHAR (30)    NOT NULL,
    [wReqStaffRid]          BIGINT          CONSTRAINT [DF_eGift_wReqStaffRid] DEFAULT ((-1)) NOT NULL,
    [wReqAgentCodeIn]       VARCHAR (14)    NOT NULL,
    [wDate]                 DATE            NOT NULL,
    [wRecipient]            NVARCHAR (50)   NOT NULL,
    [wRecipientAgentCodeIn] VARCHAR (14)    CONSTRAINT [DF_eGift_wRecipientAgentCodeIn] DEFAULT ('') NOT NULL,
    [wCurrCode]             VARCHAR (6)     NOT NULL,
    [wAmount]               NUMERIC (18, 4) NOT NULL,
    [wType]                 VARCHAR (30)    NOT NULL,
    [wSubType]              VARCHAR (30)    NOT NULL,
    [wIsReceived]           CHAR (1)        CONSTRAINT [DF_eGift_wIsReceived] DEFAULT ('N') NOT NULL,
    [wRemark]               NVARCHAR (500)  NOT NULL,
    [wEventCodeRid]         BIGINT          CONSTRAINT [DF_eGift_wEventCodeRid] DEFAULT ((-1)) NOT NULL,
    [wStatus]               CHAR (1)        CONSTRAINT [DF_eGift_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtDt]                DATETIME2 (7)   NOT NULL,
    [wCrtBy]                BIGINT          NOT NULL,
    [wUpdDt]                DATETIME2 (7)   NOT NULL,
    [wUpdBy]                BIGINT          NOT NULL,
    [wReasonCd]             VARCHAR (30)    CONSTRAINT [DF_eGift_wReasonCd] DEFAULT ('') NOT NULL,
    [wDebitCounterRid]      BIGINT          NOT NULL,
    [wCost]                 NUMERIC (18, 4) NULL,
    CONSTRAINT [PK_eGift] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






















GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Corresponding RowID of the data table record', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eGift', @level2type = N'COLUMN', @level2name = N'wRefTableRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Corresponding data table name', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eGift', @level2type = N'COLUMN', @level2name = N'wRefTableName';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Corresponding RowID of the booking record', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eGift', @level2type = N'COLUMN', @level2name = N'wRefBookingRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'扣數櫃台', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eGift', @level2type = N'COLUMN', @level2name = N'wDebitCounterRid';


GO
CREATE NONCLUSTERED INDEX [PI_eGift_01]
    ON [dbo].[eGift]([wReqAgentCodeIn] ASC, [wStatus] ASC, [wDate] ASC);

