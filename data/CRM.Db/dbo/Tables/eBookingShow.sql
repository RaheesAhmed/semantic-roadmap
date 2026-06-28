CREATE TABLE [dbo].[eBookingShow] (
    [RowID]            BIGINT          NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wShowRid]         BIGINT          NOT NULL,
    [wOrderNo]         NVARCHAR (30)   NOT NULL,
    [wTravelAgencyRid] BIGINT          NOT NULL,
    [wSupplier]        VARCHAR (2)     NOT NULL,
    [wShowDt]          DATETIME2 (7)   NOT NULL,
    [wCurrCode]        VARCHAR (6)     NOT NULL,
    [wTotalAmt]        NUMERIC (18, 4) NOT NULL,
    [wExpenseAmt]      NUMERIC (18, 4) NOT NULL,
    [wTotalCost]       NUMERIC (18, 4) NOT NULL,
    [wPaymentMethod]   VARCHAR (30)    NOT NULL,
    [wUseBlackCard]    CHAR (1)        NOT NULL,
    [wRemark]          NVARCHAR (500)  NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eBookingShow_wStatus] DEFAULT ('A') NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wTotalQuantity]   INT             NOT NULL,
    [wReceiptNo]       NVARCHAR (50)   CONSTRAINT [DF_eBookingShow_wReceiptNo] DEFAULT ('') NOT NULL,
    [wHaveTicket]      CHAR (1)        CONSTRAINT [DF_eBookingShow_wHaveTicket_1] DEFAULT ('N') NOT NULL,
    [wScalpedTicket]   CHAR (1)        CONSTRAINT [DF_eBookingShow_wScalpedTicket_1] DEFAULT ('N') NOT NULL,
    [wGetTicketTime]   DATETIME2 (7)   CONSTRAINT [DF_eBookingShow_wGetTicketTime_1] DEFAULT (getdate()) NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eBookingShow_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wOtherName]       NVARCHAR (100)  CONSTRAINT [DF_eBookingShow_wOtherName] DEFAULT ('') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eBookingShow_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingShow] PRIMARY KEY CLUSTERED ([RowID] ASC)
);









