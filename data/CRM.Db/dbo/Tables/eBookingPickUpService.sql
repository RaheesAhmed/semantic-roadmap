CREATE TABLE [dbo].[eBookingPickUpService] (
    [RowID]            BIGINT          NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wOrderNo]         NVARCHAR (60)   NOT NULL,
    [wServiceType]     VARCHAR (3)     NOT NULL,
    [wApplyDt]         DATETIME2 (7)   NOT NULL,
    [wDriverName]      NVARCHAR (100)  NOT NULL,
    [wDriverPhone]     NVARCHAR (15)   NOT NULL,
    [wCarNo]           VARCHAR (10)    NOT NULL,
    [wQuantity]        INT             CONSTRAINT [DF_eBookingPickUpService_wQuantity] DEFAULT ((0)) NOT NULL,
    [wCurrCode]        VARCHAR (6)     NOT NULL,
    [wPaymentMethod]   VARCHAR (30)    NOT NULL,
    [wExpenseAmt]      NUMERIC (18, 4) NOT NULL,
    [wTotalAmt]        NUMERIC (18, 4) NOT NULL,
    [wTotalCost]       NUMERIC (18, 4) NOT NULL,
    [wRemark]          NVARCHAR (500)  NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eBookingPickUpService_wStatus] DEFAULT ('A') NOT NULL,
    [wReceiptNo]       NVARCHAR (50)   CONSTRAINT [DF_eBookingPickUpService_wReceiptNo] DEFAULT ('') NOT NULL,
    [wSeqNo]           INT             NOT NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wTravelAgencyRid] BIGINT          CONSTRAINT [DF_eBookingPickUpService_wTravelAgencyRid] DEFAULT ((-1)) NOT NULL,
    [wRelatedOrderNo]  NVARCHAR (60)   CONSTRAINT [DF_eBookingPickUpService_wRelatedOrderNo] DEFAULT ('') NOT NULL,
    [wDisplayName]     NVARCHAR (100)  CONSTRAINT [DF_eBookingPickUpService_wDisplayName] DEFAULT ('') NOT NULL,
    [wUnitPrice]       NUMERIC (18, 4) CONSTRAINT [DF_eBookingPickUpService_wUnitPrice] DEFAULT ((0)) NOT NULL,
    [wAdditionalExp]   NUMERIC (18, 4) CONSTRAINT [DF_eBookingPickUpService_wAdditionalExp] DEFAULT ((0)) NOT NULL,
    [wUseBlackCard]    CHAR (1)        CONSTRAINT [DF_eBookingPickUpService_wUseBlackCard] DEFAULT ('N') NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eBookingPickUpService_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wFlightNo]        VARCHAR (30)    CONSTRAINT [DF_eBookingPickUpService_wFlightNo] DEFAULT ('') NOT NULL,
    [wDepartAirport]   VARCHAR (50)    CONSTRAINT [DF_eBookingPickUpService_wDepartAirport] DEFAULT ('') NOT NULL,
    [wDestination]     VARCHAR (50)    CONSTRAINT [DF_eBookingPickUpService_wDestination] DEFAULT ('') NOT NULL,
    [wDepartDt]        DATETIME2 (7)   CONSTRAINT [DF_eBookingPickUpService_wDepartDt] DEFAULT ('0001-01-01 00:00:00.0000000') NOT NULL,
    [wArrivalDt]       DATETIME2 (7)   CONSTRAINT [DF_eBookingPickUpService_wArrivalDt] DEFAULT ('0001-01-01 00:00:00.0000000') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eBookingPickUpService_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingPickUpService] PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO
CREATE NONCLUSTERED INDEX [PI_eBookingPickUpService_01]
    ON [dbo].[eBookingPickUpService]([wBookingRid] ASC);

