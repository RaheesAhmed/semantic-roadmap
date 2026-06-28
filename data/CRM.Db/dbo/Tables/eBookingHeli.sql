CREATE TABLE [dbo].[eBookingHeli] (
    [RowID]              BIGINT          NOT NULL,
    [wBookingRid]        BIGINT          NOT NULL,
    [wTicketId]          BIGINT          NOT NULL,
    [wOrderNo]           NVARCHAR (20)   NOT NULL,
    [wBookingLocation]   VARCHAR (20)    NOT NULL,
    [wUseBlackCardFlag]  CHAR (1)        NOT NULL,
    [wPaymentMethod]     VARCHAR (30)    NOT NULL,
    [wReceiptNo]         NVARCHAR (50)   CONSTRAINT [DF_eBookingHeli_wReceiptNo] DEFAULT ('') NOT NULL,
    [wRouteRid]          BIGINT          NOT NULL,
    [wDepartDt]          DATETIME2 (7)   NOT NULL,
    [wUnitAmt]           NUMERIC (18, 4) NOT NULL,
    [wQuantity]          INT             NOT NULL,
    [wExpAmt]            NUMERIC (18, 4) CONSTRAINT [DF_eBookingHeli_wExpAmt] DEFAULT ((0)) NOT NULL,
    [wTotalAmt]          NUMERIC (18, 4) CONSTRAINT [DF_eBookingHeli_wTotalAmt] DEFAULT ((0)) NOT NULL,
    [wCost]              NUMERIC (18, 4) CONSTRAINT [DF_eBookingHeli_wCost] DEFAULT ((0)) NOT NULL,
    [wCurrCode]          VARCHAR (6)     NOT NULL,
    [wAdditionalExp]     NUMERIC (18, 4) NOT NULL,
    [wRemark]            NVARCHAR (500)  NOT NULL,
    [wSeqNo]             INT             NOT NULL,
    [wCrtDt]             DATETIME2 (7)   NOT NULL,
    [wCrtBy]             BIGINT          NOT NULL,
    [wUpdDt]             DATETIME2 (7)   NOT NULL,
    [wUpdBy]             BIGINT          NOT NULL,
    [wBookingStatus]     VARCHAR (5)     CONSTRAINT [DF_eBookingHeli_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wStatus]            CHAR (1)        CONSTRAINT [DF_eBookingHeli_wStatus] DEFAULT ('A') NOT NULL,
    [wHandlingFee]       NUMERIC (18, 4) CONSTRAINT [DF_eBookingHeli_wHandlingFee] DEFAULT ((0)) NOT NULL,
    [wIsCharteredFlight] CHAR (1)        CONSTRAINT [DF_eBookingHeli_wIsCharteredFlight_1] DEFAULT ('') NOT NULL,
    [wChangeOrderCount]  INT             CONSTRAINT [DF_eBookingHeli_wChangeOrderCount_1] DEFAULT ((0)) NOT NULL,
    [wUnqualifiedRid]    BIGINT          CONSTRAINT [DF_eBookingHeli_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingHeli] PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'refer to LookUp.HELICOPTER_BOOKING_LOCATION', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wBookingLocation';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Use Black Card? (Checkbox)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wUseBlackCardFlag';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'The price of every single ticket', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wUnitAmt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Total price of the tickets ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wTotalAmt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'refer to mRoute.ID', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wRouteRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'If choose debit card or bank transfer, then the receipt no. field will appear and should be filled in ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wReceiptNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Refer to LookUp.PAYMENT_TYPE', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wPaymentMethod';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Expenses Amount', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wExpAmt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Departure datetime', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wDepartDt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table, (refer to CURRENCY)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wCurrCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Additional expenses for services: e.g. Handling fee for correction of tickets ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingHeli', @level2type = N'COLUMN', @level2name = N'wAdditionalExp';


GO
CREATE NONCLUSTERED INDEX [PI_eBookingHeli_01]
    ON [dbo].[eBookingHeli]([wBookingRid] ASC);

