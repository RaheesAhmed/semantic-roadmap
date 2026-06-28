CREATE TABLE [dbo].[eBookingShowTicket] (
    [RowId]               BIGINT          NOT NULL,
    [wBookingShowRid]     BIGINT          NOT NULL,
    [wShowTicketPriceRid] BIGINT          NOT NULL,
    [wQuantity]           INT             NOT NULL,
    [wAmount]             NUMERIC (18, 4) CONSTRAINT [DF_eBookingShowTicket_wAmount_1] DEFAULT ((0)) NOT NULL,
    [wCost]               NUMERIC (18, 4) CONSTRAINT [DF_eBookingShowTicket_wCost_1] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_eBookingShowTicket] PRIMARY KEY CLUSTERED ([RowId] ASC),
    CONSTRAINT [FK_eBookingShowTicketDtl_mShowTicketPrice] FOREIGN KEY ([wShowTicketPriceRid]) REFERENCES [dbo].[mShowTicketPrice] ([RowID])
);



