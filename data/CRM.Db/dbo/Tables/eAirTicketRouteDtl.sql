CREATE TABLE [dbo].[eAirTicketRouteDtl] (
    [RowID]                BIGINT        NOT NULL,
    [wType]                VARCHAR (30)  CONSTRAINT [DF_eAirTicketRouteDtl_wType] DEFAULT ((-1)) NOT NULL,
    [wTypeRid]             BIGINT        NOT NULL,
    [wPNRNo]               VARCHAR (50)  NOT NULL,
    [wLine]                INT           NOT NULL,
    [wFlightType]          VARCHAR (30)  NOT NULL,
    [wAirline]             VARCHAR (10)  NOT NULL,
    [wClassCd]             NVARCHAR (50) NOT NULL,
    [wIsReturn]            CHAR (1)      NOT NULL,
    [wDepartFlightNo]      VARCHAR (20)  NOT NULL,
    [wDepartureAirportRid] BIGINT        NOT NULL,
    [wArrivalAirportRid]   BIGINT        NOT NULL,
    [wDepartureTerminal]   NVARCHAR (50) NOT NULL,
    [wArrivalTerminal]     NVARCHAR (50) NOT NULL,
    [wTakeOffDt]           DATETIME2 (7) NOT NULL,
    [wArrivalDt]           DATETIME2 (7) NOT NULL,
    [wStatus]              CHAR (1)      NOT NULL,
    [wCrtDt]               DATETIME2 (7) NOT NULL,
    [wCrtBy]               BIGINT        NOT NULL,
    [wUpdDt]               DATETIME2 (7) NOT NULL,
    [wUpdBy]               BIGINT        NOT NULL,
    [wIsWaiting]           CHAR (1)      DEFAULT ('N') NOT NULL,
    [wExpiryDt]            DATETIME2 (7) NULL,
    [wIsDestination]       CHAR (1)      CONSTRAINT [DF__eAirTicke__wIsDe__4F6A2379] DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_eAirTicketRouteDtl] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO
CREATE NONCLUSTERED INDEX [PI_eAirTicketRouteDtl_01]
    ON [dbo].[eAirTicketRouteDtl]([wType] ASC, [wStatus] ASC)
    INCLUDE([wArrivalAirportRid], [wArrivalDt], [wDepartureAirportRid], [wTakeOffDt], [wTypeRid]);

