CREATE TABLE [dbo].[eUpdateFerryAndHeliCost] (
    [RowID]             BIGINT          NOT NULL,
    [wRouteID]          BIGINT          NOT NULL,
    [wVehicleType]      VARCHAR (20)    NOT NULL,
    [wStartDate]        DATE            NOT NULL,
    [wEndDate]          DATE            NOT NULL,
    [wTicketType]       VARCHAR (10)    NOT NULL,
    [wClassCd]          VARCHAR (5)     NOT NULL,
    [wSellingAmt]       NUMERIC (18, 4) NOT NULL,
    [wRate]             NUMERIC (18, 4) NOT NULL,
    [wTax]              NUMERIC (18, 4) NOT NULL,
    [wStatus]           CHAR (1)        CONSTRAINT [DF_eUpdateFerryAndHeliCost_wStatus] DEFAULT ('Y') NOT NULL,
    [wCrtDt]            DATETIME2 (7)   NOT NULL,
    [wCrtBy]            BIGINT          NOT NULL,
    [wUpdDt]            DATETIME2 (7)   NOT NULL,
    [wUpdBy]            BIGINT          NOT NULL,
    [wCurrCode]         VARCHAR (6)     NULL,
    [wPrice]            NUMERIC (18, 4) CONSTRAINT [DF_eUpdateFerryAndHeliCost_wPrice] DEFAULT ((0)) NOT NULL,
    [wRebatePrice]      NUMERIC (18, 4) DEFAULT ((0)) NOT NULL,
    [wCalculateCostWay] VARCHAR (10)    DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_eUpdateFerryAndHeliCost] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'HELI, FERRY', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wVehicleType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table, (refer to FERRY_TICKET_TYPE)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wTicketType';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Tax from supplier ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wTax';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'refer to LookUp.COMMON_STATUS', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wStatus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Selling Price ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wSellingAmt';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Rate from supplier', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wRate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'Enable End Date if it is a special period  ', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wEndDate';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'LookUp Table, (refer to FERRY_CLASS)   Helicopter has no wClassCd', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wClassCd';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'成本計算方式', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eUpdateFerryAndHeliCost', @level2type = N'COLUMN', @level2name = N'wCalculateCostWay';

