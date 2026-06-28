CREATE TABLE [dbo].[eBookingLeading] (
    [RowID]            BIGINT          NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wRegion]          VARCHAR (10)    NOT NULL,
    [wOrderNo]         NVARCHAR (20)   NOT NULL,
    [wNoofPolice]      INT             NOT NULL,
    [wStartDt]         DATETIME2 (7)   NOT NULL,
    [wCurrCode]        VARCHAR (6)     NOT NULL,
    [wPaymentMethod]   VARCHAR (30)    NOT NULL,
    [wReceiptNo]       NVARCHAR (50)   CONSTRAINT [DF_eBookingLeading_wReceiptNo] DEFAULT ('') NOT NULL,
    [wExpenseAmt]      NUMERIC (18, 4) NOT NULL,
    [wTotalAmt]        NUMERIC (18, 4) NOT NULL,
    [wTotalCost]       NUMERIC (18, 4) NOT NULL,
    [wRemark]          NVARCHAR (500)  NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eBookingLeading_wStatus] DEFAULT ('A') NOT NULL,
    [wSeqNo]           INT             NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wTravelAgencyRid] BIGINT          CONSTRAINT [DF_eBookingLeading_wTravelAgencyRid] DEFAULT ((-1)) NOT NULL,
    [wLang]            VARCHAR (10)    CONSTRAINT [DF_eBookingLeading_wLang] DEFAULT ('') NOT NULL,
    [wAdditionalExp]   NUMERIC (18, 4) CONSTRAINT [DF_eBookingLeading_wAdditionalExp] DEFAULT ((0)) NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eBookingLeading_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wUseBlackCard]    CHAR (1)        CONSTRAINT [DF_eBookingLeading_wUseBlackCard] DEFAULT ('N') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eBookingLeading_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingLeading] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO
CREATE NONCLUSTERED INDEX [PI_eBookingLeading_01]
    ON [dbo].[eBookingLeading]([wBookingRid] ASC, [wStatus] ASC);

