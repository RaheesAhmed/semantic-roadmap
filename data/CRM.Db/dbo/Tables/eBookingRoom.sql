CREATE TABLE [dbo].[eBookingRoom] (
    [RowID]                  BIGINT          NOT NULL,
    [wHotelBookingRid]       BIGINT          NOT NULL,
    [wRequestRid]            BIGINT          NOT NULL,
    [wHotelRid]              BIGINT          NOT NULL,
    [wHotelRoomRid]          BIGINT          NOT NULL,
    [wCounterRid]            BIGINT          NOT NULL,
    [wTravelAgencyRid]       BIGINT          NOT NULL,
    [wOrderNo]               NVARCHAR (60)   NOT NULL,
    [wBedType]               VARCHAR (30)    NOT NULL,
    [wStartDate]             DATE            NOT NULL,
    [wEndtDate]              DATE            NOT NULL,
    [wDayOfStay]             INT             NOT NULL,
    [wPaymentMethod]         VARCHAR (30)    NOT NULL,
    [wReceiptNo]             NVARCHAR (50)   NOT NULL,
    [wVoucherNo]             VARCHAR (40)    NOT NULL,
    [wConfirmationNo]        NVARCHAR (40)   NOT NULL,
    [wCashReceiptNo]         NVARCHAR (40)   NOT NULL,
    [wCashTransferReceiptNo] VARCHAR (40)    NOT NULL,
    [wGetKeyMethod]          VARCHAR (30)    NOT NULL,
    [wCurrCode]              CHAR (3)        NOT NULL,
    [wUseMemberCard]         CHAR (1)        CONSTRAINT [DF_eBookingHotel_wUseMemberCard] DEFAULT ('N') NOT NULL,
    [wIncludeBreakfast]      CHAR (1)        CONSTRAINT [DF_eBookingHotel_wIncludeBreakfast] DEFAULT ('N') NOT NULL,
    [wUseExtraAllotment]     CHAR (1)        CONSTRAINT [DF_eBookingHotel_wUseExtraAlloment] DEFAULT ('N') NOT NULL,
    [wUseUpAllotment]        CHAR (1)        CONSTRAINT [DF_eBookingHotel_wUseUpAllotment] DEFAULT ('N') NOT NULL,
    [wTotalAmount]           NUMERIC (18, 4) CONSTRAINT [DF_eBookingHotel_wTotalAmount] DEFAULT ((0)) NOT NULL,
    [wAdditionalFee]         NUMERIC (18, 4) CONSTRAINT [DF_eBookingHotel_wAdjustment] DEFAULT ((0)) NOT NULL,
    [wActualTotalAmount]     NUMERIC (18, 4) NOT NULL,
    [wTotalCost]             NUMERIC (18, 4) NOT NULL,
    [wRoomNo]                NVARCHAR (20)   CONSTRAINT [DF_eBookingHotel_wRoomNo] DEFAULT ('') NOT NULL,
    [wGetKeyPasscode]        VARCHAR (10)    CONSTRAINT [DF_eBookingHotel_wGetKeyPasscode] DEFAULT ('') NOT NULL,
    [wHasStaffGetKey]        CHAR (1)        CONSTRAINT [DF_eBookingHotel_wHasStaffGetKey] DEFAULT ('N') NOT NULL,
    [wHasClientGetKey]       CHAR (1)        CONSTRAINT [DF_eBookingHotel_wHasClientGetKey] DEFAULT ('N') NOT NULL,
    [wReGetKeyDate]          DATE            NULL,
    [wSmsCount]              INT             NOT NULL,
    [wIsConsigned]           CHAR (1)        CONSTRAINT [DF_eBookingHotel_wIsConsigned] DEFAULT ('N') NOT NULL,
    [wSameFloor]             CHAR (1)        CONSTRAINT [DF_eBookingHotel_wSameFloor] DEFAULT ('N') NOT NULL,
    [wRoomExpenseState]      VARCHAR (30)    NOT NULL,
    [wCallCustomer]          CHAR (1)        CONSTRAINT [DF_eBookingHotel_wCallCustomer] DEFAULT ('N') NOT NULL,
    [wQuickCollectKey]       CHAR (1)        CONSTRAINT [DF_eBookingHotel_wQuickCollectKey] DEFAULT ('N') NOT NULL,
    [wIsCleaning]            CHAR (1)        CONSTRAINT [DF_eBookingHotel_wIsCleaning] DEFAULT ('N') NOT NULL,
    [wWarmReminderSMS]       CHAR (1)        CONSTRAINT [DF_eBookingHotel_wWarmReminderSMS] DEFAULT ('N') NOT NULL,
    [wNoteRemark]            CHAR (1)        CONSTRAINT [DF_eBookingHotel_wNoteRemarks] DEFAULT ('N') NOT NULL,
    [wIsConnectedRoom]       CHAR (1)        CONSTRAINT [DF_eBookingHotel_wIsConnectedRoom] DEFAULT ('N') NOT NULL,
    [wRemark]                NVARCHAR (500)  CONSTRAINT [DF_eBookingHotel_wRemark] DEFAULT ('') NOT NULL,
    [wCrtDt]                 DATETIME2 (7)   NOT NULL,
    [wCrtBy]                 BIGINT          NOT NULL,
    [wUpdDt]                 DATETIME2 (7)   NOT NULL,
    [wUpdBy]                 BIGINT          NOT NULL,
    [wAllotmentGroupRid]     BIGINT          NOT NULL,
    [wRoomSMSSent]           CHAR (1)        CONSTRAINT [DF__eBookingR__wRoom__wRoomSMSSent] DEFAULT ('N') NOT NULL,
    [wDisplayAgencyHotel]    CHAR (1)        CONSTRAINT [DF__eBookingR__wDisplayAgencyHotel] DEFAULT ('N') NOT NULL,
    [wUseAgencyAllotment]    CHAR (1)        CONSTRAINT [DF__eBookingR__wUseAgencyAllotment] DEFAULT ('N') NOT NULL,
    [wStatus]                CHAR (1)        CONSTRAINT [DF__eBookingR__wStatus] DEFAULT ('A') NOT NULL,
    [wSeqNo]                 INT             CONSTRAINT [DF_eBookingRoom_wSeqNo] DEFAULT ((1)) NOT NULL,
    [wBookingStatus]         VARCHAR (5)     CONSTRAINT [DF_mLookUp_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wUnqualifiedRid]        BIGINT          CONSTRAINT [DF_eBookingRoom_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    [wBookingRid]            BIGINT          CONSTRAINT [DF_eBookingRoom_wBookingRid] DEFAULT ((0)) NOT NULL,
    [wCheckoutRemarks]       NVARCHAR (500)  NULL,
    [wIsSmoke]               CHAR (1)        DEFAULT ('N') NOT NULL,
    [wIsExtraBed]            CHAR (1)        DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_eBookingRoom] PRIMARY KEY CLUSTERED ([RowID] ASC)
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



GO



GO



GO



GO



GO
CREATE NONCLUSTERED INDEX [PI_eBookingRoom_01]
    ON [dbo].[eBookingRoom]([wHotelBookingRid] ASC, [wStatus] ASC);


GO
CREATE NONCLUSTERED INDEX [PI_eBookingRoom_03]
    ON [dbo].[eBookingRoom]([wOrderNo] ASC, [wStatus] ASC, [wStartDate] ASC, [wEndtDate] ASC);


GO
CREATE NONCLUSTERED INDEX [PI_eBookingRoom_02]
    ON [dbo].[eBookingRoom]([wRoomNo] ASC, [wStatus] ASC, [wStartDate] ASC, [wEndtDate] ASC);


GO



GO
CREATE NONCLUSTERED INDEX [PI_eBookingRoom_05]
    ON [dbo].[eBookingRoom]([wStatus] ASC, [wBookingRid] ASC)
    INCLUDE([RowID], [wBookingStatus], [wEndtDate], [wStartDate]);


GO
CREATE NONCLUSTERED INDEX [PI_eBookingRoom_04]
    ON [dbo].[eBookingRoom]([wStatus] ASC, [wEndtDate] ASC, [wBookingStatus] ASC)
    INCLUDE([RowID], [wBookingRid], [wStartDate]);

