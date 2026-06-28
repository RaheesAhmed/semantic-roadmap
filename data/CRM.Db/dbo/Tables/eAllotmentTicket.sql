CREATE TABLE [dbo].[eAllotmentTicket] (
    [RowID]            BIGINT          NOT NULL,
    [wTicketNo]        VARCHAR (30)    NOT NULL,
    [wCounterRid]      BIGINT          NOT NULL,
    [wExpiryDate]      DATE            NULL,
    [wTicketType]      VARCHAR (30)    CONSTRAINT [DF_eAllotmentTicket_wTicketType] DEFAULT ('FERRY') NOT NULL,
    [wRouteRid]        BIGINT          NULL,
    [wClassCd]         VARCHAR (10)    NOT NULL,
    [wAmount]          NUMERIC (18, 4) NOT NULL,
    [wRemark]          NVARCHAR (500)  CONSTRAINT [DF_eAllotmentTicket_wRemark] DEFAULT ('') NOT NULL,
    [wAllotmentStatus] VARCHAR (30)    NOT NULL,
    [wStatus]          CHAR (1)        CONSTRAINT [DF_eAllotmentTicket_wStatus] DEFAULT ('A') NOT NULL,
    [wBookingRid]      BIGINT          NULL,
    [wCrtDt]           DATETIME2 (7)   NOT NULL,
    [wCrtBy]           BIGINT          NOT NULL,
    [wUpdDt]           DATETIME2 (7)   NOT NULL,
    [wUpdBy]           BIGINT          NOT NULL,
    [wSvCtrCode]       NVARCHAR (15)   NULL,
    [wCurrCode]        VARCHAR (6)     NULL,
    [wInitialsTkt]     VARCHAR (20)    NULL,
    [wTicketNum]       INT             NOT NULL,
    CONSTRAINT [PK_eAllotmentTicket] PRIMARY KEY CLUSTERED ([RowID] ASC)
);











