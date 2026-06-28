CREATE TABLE [dbo].[eBookingFerry] (
    [RowID]            BIGINT          NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wClassCd]         VARCHAR (30)    NOT NULL,
    [wTicketType]      VARCHAR (30)    NOT NULL,
    [wPaymentMethod]   VARCHAR (30)    NOT NULL,
    [wRouteRid]        BIGINT          NOT NULL,
    [wDepartDt]        DATETIME2 (7)   NULL,
    [wCurrCode]        VARCHAR (6)     NOT NULL,
    [wExpAmt]          NUMERIC (18, 4) CONSTRAINT [DF_eBookingFerry_wExpAmt] DEFAULT ((0)) NOT NULL,
    [wQuantity]        INT             CONSTRAINT [DF_eBookingFerry_wQuantity] DEFAULT ((0)) NOT NULL,
    [wTotalAmt]        NUMERIC (18, 4) CONSTRAINT [DF_eBookingFerry_wTotalAmt] DEFAULT ((0)) NOT NULL,
    [wCost]            NUMERIC (18, 4) CONSTRAINT [DF_eBookingFerry_wCost] DEFAULT ((0)) NOT NULL,
    [wRemark]          NVARCHAR (500)  CONSTRAINT [DF_eBookingFerry_wRemark] DEFAULT ('') NOT NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wOrderNo]         NVARCHAR (20)   CONSTRAINT [DF_eBookingFerry_wOrderNo] DEFAULT ('') NOT NULL,
    [wUnitAmt]         NUMERIC (18, 4) CONSTRAINT [DF_eBookingFerry_wUnitAmt] DEFAULT ((0)) NOT NULL,
    [wSeqNo]           INT             CONSTRAINT [DF_eBookingFerry_wSeqNo] DEFAULT ((0)) NOT NULL,
    [wTicketId]        BIGINT          CONSTRAINT [DF_eBookingFerry_wTicketId] DEFAULT ((0)) NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eBookingFerry_wStatus] DEFAULT ('A') NOT NULL,
    [wUseBlackCard]    CHAR (1)        CONSTRAINT [DF_eBookingFerry_wUseBlackCard] DEFAULT ('N') NOT NULL,
    [wReceiptNo]       NVARCHAR (50)   CONSTRAINT [DF_eBookingFerry_WReceiptNo] DEFAULT ('') NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eBookingFerry_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wWaived]          CHAR (1)        CONSTRAINT [DF_eBookingFerry_wWaived] DEFAULT ('N') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eBookingFerry_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    [wTravelAgencyRid] BIGINT          CONSTRAINT [DF__eBookingF__wTrav__70603799] DEFAULT ((0)) NOT NULL,
    [wURLType]         VARCHAR (10)    DEFAULT ('') NOT NULL,
    [wURLAddress]      NVARCHAR (200)  DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_eBookingFerry] PRIMARY KEY CLUSTERED ([RowID] ASC)
);


















GO
CREATE NONCLUSTERED INDEX [PI_eBookingFerry_01]
    ON [dbo].[eBookingFerry]([wBookingRid] ASC, [wDepartDt] ASC)
    INCLUDE([RowID], [wBookingStatus], [wClassCd], [wCost], [wCrtBy], [wCrtDt], [wCurrCode], [wExpAmt], [wOrderNo], [wPaymentMethod], [wQuantity], [wReceiptNo], [wRemark], [wRouteRid], [wSeqNo], [wStatus], [wTicketId], [wTicketType], [wTotalAmt], [wTravelAgencyRid], [wUnitAmt], [wUnqualifiedRid], [wUpdBy], [wUpdDt], [wUseBlackCard], [wWaived]);

