CREATE TABLE [dbo].[eBookingCheckInService] (
    [RowId]                 BIGINT          NOT NULL,
    [wBookingRid]           BIGINT          NOT NULL,
    [wBookDt]               DATETIME2 (7)   CONSTRAINT [DF_eCheckInService_wBookDt] DEFAULT (getdate()) NOT NULL,
    [wExpAmt]               NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wExpenseAmt] DEFAULT ((0)) NOT NULL,
    [wTotalAmt]             NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wTotalAmt] DEFAULT ((0)) NOT NULL,
    [wPaymentMethod]        VARCHAR (30)    CONSTRAINT [DF_eCheckInService_wPaymentMethod] DEFAULT ('') NOT NULL,
    [wReceiptNo]            NVARCHAR (50)   CONSTRAINT [DF_eCheckInService_wRecieptNo] DEFAULT ((0)) NOT NULL,
    [wCurrCode]             VARCHAR (6)     CONSTRAINT [DF_eCheckInService_wCurrency] DEFAULT ('HKD') NOT NULL,
    [wExtraFee]             NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wExtraFee] DEFAULT ((0)) NOT NULL,
    [wRemark]               NVARCHAR (500)  CONSTRAINT [DF_eCheckInService_wRemark] DEFAULT ('') NOT NULL,
    [wCrtBy]                BIGINT          CONSTRAINT [DF_eCheckInService_wCrtBy] DEFAULT ((0)) NOT NULL,
    [wCrtDt]                DATETIME        CONSTRAINT [DF_eCheckInService_wCrtDt] DEFAULT (getdate()) NOT NULL,
    [wTicketCollectionRid]  BIGINT          CONSTRAINT [DF_eCheckInService_wTicketCollectionRid] DEFAULT ((0)) NOT NULL,
    [wBookingDateRid]       BIGINT          CONSTRAINT [DF_eCheckInService_wBookingDateRid] DEFAULT ((0)) NOT NULL,
    [wServiceCounterRid]    BIGINT          CONSTRAINT [DF_eCheckInService_wServiceCounterRid] DEFAULT ((0)) NOT NULL,
    [wOrderNo]              NVARCHAR (50)   CONSTRAINT [DF_eCheckInService_wOrderNo] DEFAULT ((0)) NOT NULL,
    [wUpdBy]                BIGINT          CONSTRAINT [DF_eCheckInService_wUpdBy] DEFAULT ((0)) NOT NULL,
    [wUpdDt]                DATETIME2 (7)   CONSTRAINT [DF_eCheckInService_wUpdDt] DEFAULT (getdate()) NOT NULL,
    [wSupplier]             BIGINT          CONSTRAINT [DF_eCheckInService_wSupplier_1] DEFAULT ((-1)) NOT NULL,
    [wRelatedOrderNo]       NVARCHAR (50)   CONSTRAINT [DF_eCheckInService_wRelatedOrderNo_1] DEFAULT ('') NOT NULL,
    [wArrivalTimeToG15nG16] DATETIME2 (7)   CONSTRAINT [DF_eCheckInService_wArrivalTimeToG15nG16_1] DEFAULT (getdate()) NOT NULL,
    [wNoOfBaggage]          NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wNoOfBaggage_1] DEFAULT ((-1)) NOT NULL,
    [wPassengerName]        NVARCHAR (50)   CONSTRAINT [DF_eCheckInService_wPassengerName_1] DEFAULT ('') NOT NULL,
    [wPassengerPhoneTel]    NVARCHAR (50)   CONSTRAINT [DF_eCheckInService_wPassengerPhoneTel_1] DEFAULT ('') NOT NULL,
    [wVIPRoom]              CHAR (1)        CONSTRAINT [DF_eCheckInService_wVIPRoom_1] DEFAULT ('') NOT NULL,
    [wVIPRoomPrice]         NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wVIPRoomPrice_1] DEFAULT ((-1)) NOT NULL,
    [wUnitPrice]            NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wUnitPrice_1] DEFAULT ((-1)) NOT NULL,
    [wQuantity]             NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wQuantity_1] DEFAULT ((-1)) NOT NULL,
    [wCost]                 NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wCost_1] DEFAULT ((-1)) NOT NULL,
    [wSeatRequest]          NVARCHAR (50)   CONSTRAINT [DF_eCheckInService_wSeatRequest_1] DEFAULT ('') NOT NULL,
    [wAdditionalFee]        NUMERIC (18, 4) CONSTRAINT [DF_eCheckInService_wAdditionalFee_1] DEFAULT ((0)) NOT NULL,
    [wCheckInRemarks]       NVARCHAR (50)   CONSTRAINT [DF_eCheckInService_wCheckInRemarks_1] DEFAULT ('') NOT NULL,
    [wFlightNo]             VARCHAR (30)    CONSTRAINT [DF_eBookingCheckInService_wFlightNo_1] DEFAULT ('') NOT NULL,
    [wDepartAirport]        VARCHAR (50)    CONSTRAINT [DF_eBookingCheckInService_wDepartAirport_1] DEFAULT ('') NOT NULL,
    [wDestination]          VARCHAR (50)    CONSTRAINT [DF_eBookingCheckInService_wDestination_1] DEFAULT ('') NOT NULL,
    [wDepartDt]             DATETIME2 (7)   CONSTRAINT [DF_eBookingCheckInService_wDepartDt_1] DEFAULT ('0001-01-01 00:00:00.0000000') NOT NULL,
    [wArrivalDt]            DATETIME2 (7)   CONSTRAINT [DF_eBookingCheckInService_wArrivalDt_1] DEFAULT ('0001-01-01 00:00:00.0000000') NOT NULL,
    [wBookingStatus]        VARCHAR (5)     CONSTRAINT [DF_eCheckInService_wStatus] DEFAULT ('P') NOT NULL,
    [wUnqualifiedRid]       BIGINT          CONSTRAINT [DF_eBookingCheckInService_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    [wStatus]               CHAR (1)        CONSTRAINT [DF_eBookingCheckInService_wStatus] DEFAULT ('A') NOT NULL,
    CONSTRAINT [PK_eCheckInService] PRIMARY KEY CLUSTERED ([RowId] ASC)
);














GO
CREATE NONCLUSTERED INDEX [PI_eBookingCheckInService_01]
    ON [dbo].[eBookingCheckInService]([wBookingRid] ASC);

