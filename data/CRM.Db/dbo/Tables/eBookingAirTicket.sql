CREATE TABLE [dbo].[eBookingAirTicket] (
    [RowID]            BIGINT          NOT NULL,
    [wBookingRid]      BIGINT          NOT NULL,
    [wOrderNo]         NVARCHAR (20)   NOT NULL,
    [wTravelAgencyRid] BIGINT          CONSTRAINT [DF_eBookingAirTicket_wTravelAgency] DEFAULT ((-1)) NOT NULL,
    [wExpiryDt]        DATETIME2 (7)   NOT NULL,
    [wQuantity]        INT             NOT NULL,
    [wExpAmt]          NUMERIC (18, 4) NOT NULL,
    [wTotalAmt]        NUMERIC (18, 4) NOT NULL,
    [wTotalCost]       NUMERIC (18, 4) NOT NULL,
    [wIsRefund]        CHAR (1)        NOT NULL,
    [wChangeTicket]    VARCHAR (10)    NOT NULL,
    [wPaymentMethod]   VARCHAR (30)    NOT NULL,
    [wReceiptNo]       NVARCHAR (50)   CONSTRAINT [DF_eBookingAirTicket_wReceiptNo] DEFAULT ('') NOT NULL,
    [wCurrCode]        VARCHAR (10)    NOT NULL,
    [wAdditionalExp]   NUMERIC (18, 4) NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eBookingAirTicket_wStatus_1] DEFAULT ('A') NOT NULL,
    [wSeqNo]           INT             NOT NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wRemark]          NVARCHAR (500)  NOT NULL,
    [wFlightType]      VARCHAR (30)    CONSTRAINT [DF_eBookingAirTicket_wFlightType] DEFAULT ((-1)) NOT NULL,
    [wBookingStatus]   VARCHAR (5)     CONSTRAINT [DF_eBookingAirTicket_wStatus] DEFAULT ('P') NOT NULL,
    [wUnqualifiedRid]  BIGINT          CONSTRAINT [DF_eBookingAirTicket_wUnqualifiedRid] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingAirTicket] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






















GO



GO



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table, (refer to AIR_TICKET_CHANGE_OPTION)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingAirTicket', @level2type = N'COLUMN', @level2name = N'wChangeTicket';




GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'refer to mPerson ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingAirTicket', @level2type = N'COLUMN', @level2name = N'wTravelAgencyRid';




GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'If choose debit card or bank transfer, then the receipt no. field will appear and should be filled in ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingAirTicket', @level2type = N'COLUMN', @level2name = N'wReceiptNo';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table, (refer to PAYMENT_TYPE)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingAirTicket', @level2type = N'COLUMN', @level2name = N'wPaymentMethod';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'(refer to CURRENCY)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingAirTicket', @level2type = N'COLUMN', @level2name = N'wCurrCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Additional expenses for services: e.g. Handling fee for correction of tickets ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eBookingAirTicket', @level2type = N'COLUMN', @level2name = N'wAdditionalExp';


GO
CREATE NONCLUSTERED INDEX [PI_eBookingAirTicket_01]
    ON [dbo].[eBookingAirTicket]([wBookingRid] ASC);

