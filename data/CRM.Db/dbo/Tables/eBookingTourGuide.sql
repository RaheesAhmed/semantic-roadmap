CREATE TABLE [dbo].[eBookingTourGuide] (
    [RowID]            BIGINT          NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wRegion]          VARCHAR (10)    NOT NULL,
    [wTravelAgencyRid] BIGINT          NOT NULL,
    [wLang]            VARCHAR (3)     NOT NULL,
    [wOrderNo]         NVARCHAR (60)   NOT NULL,
    [wStartDt]         DATETIME2 (7)   NOT NULL,
    [wEndtDt]          DATETIME2 (7)   NOT NULL,
    [wPaymentMethod]   VARCHAR (30)    NOT NULL,
    [wPeriod]          NVARCHAR (50)   CONSTRAINT [DF_eBookingTour_wPeriod] DEFAULT ('') NOT NULL,
    [wExpenseAmt]      NUMERIC (18, 4) NOT NULL,
    [wTotalAmt]        NUMERIC (18, 4) NOT NULL,
    [wCost]            NUMERIC (18, 4) CONSTRAINT [DF_eBookingTour_wCost] DEFAULT ((0)) NOT NULL,
    [wAdditionalExp]   NUMERIC (18, 4) CONSTRAINT [DF_eBookingTour_wAdditionalExp] DEFAULT ((0)) NOT NULL,
    [wCurrCode]        VARCHAR (6)     NOT NULL,
    [wRemark]          NVARCHAR (500)  NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eBookingTourGuide_wStatus] DEFAULT ('A') NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eBookingTourGuide_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wReceiptNo]       NVARCHAR (50)   CONSTRAINT [DF_eBookingTour_wReceiptNo] DEFAULT ('') NOT NULL,
    [wSeqNo]           INT             NOT NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wIsUseBlackCard]  CHAR (1)        CONSTRAINT [DF_eBookingTour_wIsUseBlackCard] DEFAULT ('N') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eBookingTourGuide_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingTour1] PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO
CREATE NONCLUSTERED INDEX [PI_eBookingTourGuide_01]
    ON [dbo].[eBookingTourGuide]([wBookingRid] ASC);

