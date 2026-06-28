CREATE TABLE [dbo].[eHotelChange] (
    [RowID]                  BIGINT          NOT NULL,
    [wRoomBookingRid]        BIGINT          NOT NULL,
    [wAllotmentRid]          BIGINT          NOT NULL,
    [wAction]                VARCHAR (5)     NOT NULL,
    [wOriStartDate]          DATE            NOT NULL,
    [wOriEndDate]            DATE            NOT NULL,
    [wNewStartDate]          DATE            NOT NULL,
    [wNewEndDate]            DATE            NOT NULL,
    [wDayOfStay]             INT             NOT NULL,
    [wVoucherNo]             VARCHAR (40)    NOT NULL,
    [wCashReceiptNo]         NVARCHAR (40)   NOT NULL,
    [wCashTransferReceiptNo] VARCHAR (40)    NOT NULL,
    [wUseMemeberCard]        CHAR (1)        CONSTRAINT [DF_eHotelChange_wUseMemeberCard] DEFAULT ('N') NOT NULL,
    [wUseExtraAllotment]     CHAR (1)        CONSTRAINT [DF_eHotelChange_wUseExtraAllotment] DEFAULT ('N') NOT NULL,
    [wUseUpAllotment]        CHAR (1)        NOT NULL,
    [wGetKeyMethod]          VARCHAR (30)    NOT NULL,
    [wReGetKey]              CHAR (1)        CONSTRAINT [DF_eHotelChange_wReGetKey] DEFAULT ('N') NOT NULL,
    [wChangeCheckinPwd]      CHAR (1)        CONSTRAINT [DF_eHotelChange_wChangeCheckinPwd] DEFAULT ('N') NOT NULL,
    [wCurrCode]              CHAR (3)        NOT NULL,
    [wPaymentMethod]         VARCHAR (30)    NOT NULL,
    [wRemark]                NVARCHAR (500)  CONSTRAINT [DF_eHotelChange_wRemark] DEFAULT ('') NOT NULL,
    [wCrtDt]                 DATETIME2 (7)   NOT NULL,
    [wCrtBy]                 BIGINT          NOT NULL,
    [wUpdDt]                 DATETIME2 (7)   NOT NULL,
    [wUpdBy]                 BIGINT          NOT NULL,
    [wOrderNo]               NVARCHAR (60)   CONSTRAINT [DF_eHotelChange_wOrderNo] DEFAULT ('') NOT NULL,
    [wAmountChange]          NUMERIC (18, 4) CONSTRAINT [DF_eHotelChange_wAmountChange] DEFAULT ((0)) NOT NULL,
    [wBookingRid]            BIGINT          CONSTRAINT [DF_eHotelChange_wBookingRid] DEFAULT ((0)) NOT NULL,
    [wCostChange]            NUMERIC (18, 4) CONSTRAINT [DF__eHotelCha__wCost__2F132DD7] DEFAULT ((0)) NOT NULL,
    [wTotalAmount]           NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wTotalCost]             NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wDateChange]            NVARCHAR (64)   NULL,
    CONSTRAINT [PK_eHotelChange] PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO





GO



GO



GO



GO
CREATE NONCLUSTERED INDEX [PI_eHotelChange_01]
    ON [dbo].[eHotelChange]([wRoomBookingRid] ASC, [wAction] ASC);

