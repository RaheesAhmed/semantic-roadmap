CREATE TABLE [dbo].[eBooking] (
    [RowID]                BIGINT           NOT NULL,
    [wBookingType]         VARCHAR (30)     NOT NULL,
    [wRefNo]               VARCHAR (30)     NOT NULL,
    [GUID]                 UNIQUEIDENTIFIER NOT NULL,
    [wReqCounterRid]       BIGINT           NOT NULL,
    [wDebitCounterRid]     BIGINT           NOT NULL,
    [wReqAgentCodeIn]      VARCHAR (14)     NOT NULL,
    [wDebitAgentCodeIn]    VARCHAR (14)     NOT NULL,
    [wReqCustomerRid]      BIGINT           NOT NULL,
    [wDebitCustomerRid]    BIGINT           NOT NULL,
    [wReqDepartment]       VARCHAR (30)     NOT NULL,
    [wReqUserRid]          BIGINT           NOT NULL,
    [wAsstBooker]          NVARCHAR (50)    NOT NULL,
    [wAssBookerTel]        VARCHAR (100)    NOT NULL,
    [wApprovalAgentCodeIn] VARCHAR (14)     NOT NULL,
    [wDebitDt]             DATETIME2 (7)    NOT NULL,
    [wExpDt]               DATETIME2 (7)    NOT NULL,
    [wCancelDebitDt]       DATETIME2 (7)    NULL,
    [wCancelReasonCd]      VARCHAR (30)     NULL,
    [wCancelBy]            BIGINT           NULL,
    [wCancelDt]            DATETIME2 (7)    NULL,
    [wCrtDt]               DATETIME2 (7)    NOT NULL,
    [wCrtBy]               BIGINT           NOT NULL,
    [wUpdDt]               DATETIME2 (7)    NOT NULL,
    [wUpdBy]               BIGINT           NOT NULL,
    [wTravePkgRid]         BIGINT           DEFAULT ((0)) NOT NULL,
    [wEventCodeRid]        BIGINT           NOT NULL,
    [wAsstBookerEmail]     NVARCHAR (50)    CONSTRAINT [DF_eBooking_wAsstBookerEmail] DEFAULT ('') NOT NULL,
    [wDeptFollwedCd]       VARCHAR (30)     CONSTRAINT [DF_eBooking_wDeptFollwedCd] DEFAULT ('') NOT NULL,
    [wStaffFollwedRid]     BIGINT           CONSTRAINT [DF_eBooking_wStaffFollwedRid] DEFAULT ((-1)) NOT NULL,
    [wStaffTelephone]      VARCHAR (100)    CONSTRAINT [DF_eBooking_wStaffTelephone] DEFAULT ('') NOT NULL,
    [wOwnerAuthTelephone]  VARCHAR (100)    CONSTRAINT [DF_eBooking_wOwnerAuthTelephone] DEFAULT ('') NOT NULL,
    [wOtherReason]         NVARCHAR (200)   CONSTRAINT [DF_eBooking_wOtherReason] DEFAULT ('') NOT NULL,
    [wDepositAmt]          NUMERIC (18, 4)  CONSTRAINT [DF_eBooking_wDepositAmt] DEFAULT ((0)) NOT NULL,
    [wGiftReasonCd]        VARCHAR (30)     CONSTRAINT [DF_eBooking_wGiftReasonCd] DEFAULT ('') NOT NULL,
    [wUseTravelPkg]        CHAR (1)         DEFAULT ('N') NULL,
    [wHasDeposit]          CHAR (1)         DEFAULT ('N') NOT NULL,
    [wDepositDebitDt]      DATETIME2 (7)    NOT NULL,
    [wBookingStatus]       VARCHAR (10)     CONSTRAINT [DF__eBooking__wBooki__0EBAA187] DEFAULT ('') NOT NULL,
    [wCoordinator]         NVARCHAR (50)    DEFAULT ('') NOT NULL,
    [wUser]                NVARCHAR (50)    DEFAULT ('') NOT NULL,
    [wIsUser]              CHAR (1)         DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_eBooking] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






























GO



GO



GO
CREATE NONCLUSTERED INDEX [PI_eBooking_01]
    ON [dbo].[eBooking]([wDebitDt] ASC);


GO
CREATE NONCLUSTERED INDEX [PI_eBooking_02]
    ON [dbo].[eBooking]([wDebitDt] ASC)
    INCLUDE([RowID], [wDebitAgentCodeIn], [wDebitCounterRid]);


GO
CREATE NONCLUSTERED INDEX [PI_eBooking_03]
    ON [dbo].[eBooking]([wReqAgentCodeIn] ASC);


GO
CREATE NONCLUSTERED INDEX [PI_eBooking_04]
    ON [dbo].[eBooking]([wDebitCounterRid] ASC)
    INCLUDE([RowID], [wDebitAgentCodeIn], [wReqAgentCodeIn]);


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'是否選擇旅遊套票', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBooking', @level2type = N'COLUMN', @level2name = N'wUseTravelPkg';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'是否set過按金', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBooking', @level2type = N'COLUMN', @level2name = N'wHasDeposit';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'按金日期', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBooking', @level2type = N'COLUMN', @level2name = N'wDepositDebitDt';


GO
CREATE NONCLUSTERED INDEX [PI_eBooking_05]
    ON [dbo].[eBooking]([wTravePkgRid] ASC)
    INCLUDE([RowID]);

