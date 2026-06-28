CREATE TABLE [dbo].[eBookingPrivatePlane] (
    [RowID]               BIGINT          NOT NULL,
    [wBookingRid]         BIGINT          NOT NULL,
    [wPlaneModel]         NVARCHAR (50)   NOT NULL,
    [wSupplier]           NVARCHAR (50)   NOT NULL,
    [wHotelRid]           BIGINT          NULL,
    [wTravelAgencyRid]    BIGINT          NULL,
    [wSeatNo]             VARCHAR (10)    NOT NULL,
    [wOrderNo]            NVARCHAR (20)   NOT NULL,
    [wIsSmoking]          CHAR (2)        NOT NULL,
    [wServiceLang]        NVARCHAR (50)   NOT NULL,
    [wHasWifi]            CHAR (2)        NOT NULL,
    [wNoOfServiceStaff]   INT             NOT NULL,
    [wExpAmt]             NUMERIC (18, 4) NOT NULL,
    [wTotalAmt]           NUMERIC (18, 4) NOT NULL,
    [wPaymentMethod]      VARCHAR (30)    NOT NULL,
    [wReceiptNo]          NVARCHAR (50)   CONSTRAINT [DF_eBookingPrivatePlane_wReceiptNo] DEFAULT ('') NOT NULL,
    [wCurrCode]           VARCHAR (10)    NOT NULL,
    [wExtraFee]           NUMERIC (18, 4) NOT NULL,
    [wConfirmPassengerNo] NVARCHAR (50)   NOT NULL,
    [wRemark]             NVARCHAR (500)  NOT NULL,
    [wChangeOrderCount]   INT             NOT NULL,
    [wBookingNo]          VARCHAR (20)    NOT NULL,
    [wCancelDt]           DATETIME2 (7)   NOT NULL,
    [wCancelReason]       NVARCHAR (500)  NOT NULL,
    [wStatus]             CHAR (1)        CONSTRAINT [DF_eBookingPrivatePlane_wStatus_1] DEFAULT ('A') NOT NULL,
    [wCrtDt]              DATETIME2 (7)   NOT NULL,
    [wCrtBy]              BIGINT          NOT NULL,
    [wUpdDt]              DATETIME2 (7)   NOT NULL,
    [wUpdBy]              BIGINT          NOT NULL,
    [wBookingType]        VARCHAR (30)    NOT NULL,
    [wBookingStatus]      VARCHAR (5)     CONSTRAINT [DF_eBookingPrivatePlane_wStatus] DEFAULT ('P') NOT NULL,
    [wTotalCost]          NUMERIC (18, 4) CONSTRAINT [DF_eBookingPrivatePlane_wTotalCost] DEFAULT ('0') NOT NULL,
    [wIsUseBlackCard]     CHAR (1)        CONSTRAINT [DF_eBookingPrivatePlane_wIsUseBlackCard] DEFAULT ('N') NOT NULL,
    [wUnqualifiedRid]     BIGINT          CONSTRAINT [DF_eBookingPrivatePlane_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingPrivatePlane] PRIMARY KEY CLUSTERED ([RowID] ASC)
);













