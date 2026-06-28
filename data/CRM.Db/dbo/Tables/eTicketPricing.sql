CREATE TABLE [dbo].[eTicketPricing] (
    [RowID]                 BIGINT          NOT NULL,
    [wVehicleType]          VARCHAR (20)    NOT NULL,
    [wTicketType]           VARCHAR (10)    CONSTRAINT [DF_eTicketPricing_wTicketType] DEFAULT ('FERRY') NULL,
    [wClassCd]              VARCHAR (30)    NULL,
    [wIsSpecialPeriod]      CHAR (1)        CONSTRAINT [DF_Table1_wIsSpecial] DEFAULT ('N') NOT NULL,
    [wCurrCode]             VARCHAR (6)     NOT NULL,
    [wAmount]               NUMERIC (18, 4) NOT NULL,
    [wCost]                 NUMERIC (18, 4) NOT NULL,
    [wHandlingFee]          NUMERIC (18, 4) CONSTRAINT [DF_eTicketPricing_wHandlingFee] DEFAULT ((0)) NULL,
    [wStartDate]            DATE            NOT NULL,
    [wEndDate]              DATE            NULL,
    [wStatus]               CHAR (1)        CONSTRAINT [DF_eTicketPricing_wStatus] DEFAULT ('Y') NOT NULL,
    [wCrtDt]                DATETIME2 (7)   NOT NULL,
    [wCrtBy]                BIGINT          NOT NULL,
    [wUpdDt]                DATETIME2 (7)   NOT NULL,
    [wUpdBy]                BIGINT          NOT NULL,
    [wRouteId]              BIGINT          NOT NULL,
    [wCharteredAmount]      NUMERIC (18, 4) CONSTRAINT [DF_eTicketPricing_wCharteredAmount_1] DEFAULT ((-1)) NOT NULL,
    [wCharteredCost]        NUMERIC (18, 4) CONSTRAINT [DF_eTicketPricing_wCharteredCost_1] DEFAULT ((-1)) NOT NULL,
    [wCharteredHandlingFee] NUMERIC (18, 4) CONSTRAINT [DF_eTicketPricing_wCharteredHandlingFee_1] DEFAULT ((-1)) NOT NULL,
    CONSTRAINT [PK_eTicketPricing] PRIMARY KEY CLUSTERED ([RowID] ASC),
    CONSTRAINT [FK_eTicketPricing_mRoute] FOREIGN KEY ([wRouteId]) REFERENCES [dbo].[mRoute] ([RowID])
);










GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'FERRY/HELI', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eTicketPricing', @level2type = N'COLUMN', @level2name = N'wVehicleType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table, (refer to FERRY_TICKET_TYPE)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eTicketPricing', @level2type = N'COLUMN', @level2name = N'wTicketType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'refer to LookUp.COMMON_STATUS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eTicketPricing', @level2type = N'COLUMN', @level2name = N'wStatus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Fee for edit booking ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eTicketPricing', @level2type = N'COLUMN', @level2name = N'wHandlingFee';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Enable only if the period is special', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eTicketPricing', @level2type = N'COLUMN', @level2name = N'wEndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table (refer to CURRENCY)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eTicketPricing', @level2type = N'COLUMN', @level2name = N'wCurrCode';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table, (refer to FERRY_CLASS)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eTicketPricing', @level2type = N'COLUMN', @level2name = N'wClassCd';

