CREATE TABLE [dbo].[eVoucher] (
    [RowID]        BIGINT          NOT NULL,
    [wBookingRid]  BIGINT          NOT NULL,
    [wVoucherNo]   VARCHAR (20)    NOT NULL,
    [wVoucherType] NVARCHAR (50)   NOT NULL,
    [wAmount]      NUMERIC (18, 4) CONSTRAINT [DF_eVoucher_wAmount] DEFAULT ((0)) NOT NULL,
    [wCounterRid]  BIGINT          NOT NULL,
    [wLineGrp]     NVARCHAR (10)   NOT NULL,
    [wCurrCode]    VARCHAR (6)     NOT NULL,
    [wRemark]      NVARCHAR (500)  CONSTRAINT [DF_eVoucher_wRemark] DEFAULT ('') NULL,
    [wTicketType]  VARCHAR (30)    NOT NULL,
    [wSeqNo]       INT             CONSTRAINT [DF_eVoucher_wSeqNo] DEFAULT ((0)) NOT NULL,
    [wStatus]      VARCHAR (3)     CONSTRAINT [DF_eVoucher_wStatus] DEFAULT ('P') NOT NULL,
    [wCrtDt]       DATETIME2 (7)   NOT NULL,
    [wCrtBy]       BIGINT          NOT NULL,
    [wUpdDt]       DATETIME2 (7)   NOT NULL,
    [wUpdBy]       BIGINT          NOT NULL,
    [wVoucherRid]  BIGINT          NULL,
    CONSTRAINT [PK_eVoucher] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO



GO



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'[CATER: Catering][GIFT: Gift]', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eVoucher', @level2type = N'COLUMN', @level2name = N'wVoucherType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table, (refer to FERRY_TICKET_TYPE) [1:  Company Ticket][2: Ticket][3: Company Coupon][4: Lisboa Ticket]', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eVoucher', @level2type = N'COLUMN', @level2name = N'wTicketType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Code of parnter company, EG: V, VV, Q, P ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eVoucher', @level2type = N'COLUMN', @level2name = N'wLineGrp';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table (refer to CURRENCY)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eVoucher', @level2type = N'COLUMN', @level2name = N'wCurrCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Service Counter (refer to : M-Service Counter.Id)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eVoucher', @level2type = N'COLUMN', @level2name = N'wCounterRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Price of Coupon', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eVoucher', @level2type = N'COLUMN', @level2name = N'wAmount';

