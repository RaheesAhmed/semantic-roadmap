CREATE TABLE [dbo].[eBookingVisa] (
    [RowId]            BIGINT          NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wOrderNo]         NVARCHAR (50)   CONSTRAINT [DF_eBookingVisa_wOrderNo] DEFAULT ((0)) NOT NULL,
    [wApplyDt]         DATETIME2 (7)   CONSTRAINT [DF_eBookingVisa_wApplyDt] DEFAULT (getdate()) NOT NULL,
    [wPlaceOfIssue]    VARCHAR (6)     CONSTRAINT [DF_eBookingVisa_wPlaceOfIssue] DEFAULT ('') NOT NULL,
    [wCurrCode]        VARCHAR (6)     CONSTRAINT [DF_eBookingVisa_wCurrency] DEFAULT ('HKD') NOT NULL,
    [wPaymentMethod]   VARCHAR (30)    CONSTRAINT [DF_eBookingVisa_wPaymentMethod] DEFAULT ('') NOT NULL,
    [wExpAmt]          NUMERIC (18, 4) CONSTRAINT [DF_eBookingVisa_wExpenseAmt] DEFAULT ((0)) NOT NULL,
    [wTotalAmt]        NUMERIC (18, 4) CONSTRAINT [DF_eBookingVisa_wTotalAmt] DEFAULT ((0)) NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eBookingVisa_wStatus_1] DEFAULT ('A') NOT NULL,
    [wCrtBy]           BIGINT          CONSTRAINT [DF_eBookingVisa_wCrtBy] DEFAULT ((0)) NOT NULL,
    [wCrtDt]           DATETIME2 (7)   CONSTRAINT [DF_eBookingVisa_wCrtDt] DEFAULT (getdate()) NOT NULL,
    [wUpdBy]           BIGINT          CONSTRAINT [DF_eBookingVisa_wUpdBy] DEFAULT ((0)) NOT NULL,
    [wUpdDt]           DATETIME2 (7)   CONSTRAINT [DF_eBookingVisa_wUpdDt] DEFAULT (getdate()) NOT NULL,
    [wReceiptNo]       NVARCHAR (50)   CONSTRAINT [DF_eBookingVisa_wReceiptNo] DEFAULT ('') NOT NULL,
    [wTravelAgencyRid] BIGINT          CONSTRAINT [DF_eBookingVisa_wTravelAgencyRid] DEFAULT ((-1)) NOT NULL,
    [wQuantity]        INT             CONSTRAINT [DF_eBookingVisa_wQuantity] DEFAULT ((0)) NOT NULL,
    [wUnitPrice]       NUMERIC (18, 4) CONSTRAINT [DF_eBookingVisa_wUnitPrice] DEFAULT ((0)) NOT NULL,
    [wCost]            NUMERIC (18, 4) CONSTRAINT [DF_eBookingVisa_wCost] DEFAULT ((0)) NOT NULL,
    [wAdditionalExp]   NUMERIC (18, 4) CONSTRAINT [DF_eBookingVisa_wAdditionalExp] DEFAULT ((0)) NOT NULL,
    [wRemark]          NVARCHAR (500)  CONSTRAINT [DF_eBookingVisa_wRemark] DEFAULT ('') NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eBookingVisa_wStatus] DEFAULT ('P') NOT NULL,
    [wUseBlackCard]    CHAR (1)        CONSTRAINT [DF_eBookingVisa_wUseBlackCard] DEFAULT ('N') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eBookingVisa_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingVisa] PRIMARY KEY CLUSTERED ([RowId] ASC),
    CONSTRAINT [FK_eBookingVisa_eBooking] FOREIGN KEY ([wBookingRid]) REFERENCES [dbo].[eBooking] ([RowID])
);











