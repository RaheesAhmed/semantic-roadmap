CREATE TABLE [dbo].[ePrivatePlaneRouteDtl] (
    [RowID]                   BIGINT        NOT NULL,
    [wBookingPrivatePlaneRid] BIGINT        NOT NULL,
    [wLine]                   INT           NOT NULL,
    [wCityCd]                 VARCHAR (10)  NOT NULL,
    [wIsReturn]               CHAR (1)      NOT NULL,
    [wDepartureAirportRid]    BIGINT        NOT NULL,
    [wArrivalAirportRid]      BIGINT        NOT NULL,
    [wTakeOffDt]              DATETIME2 (7) NOT NULL,
    [wArrivalDt]              DATETIME2 (7) NOT NULL,
    [wStatus]                 CHAR (1)      NOT NULL,
    [wCrtDt]                  DATETIME2 (7) NOT NULL,
    [wCrtBy]                  BIGINT        NOT NULL,
    [wUpdDt]                  DATETIME2 (7) NOT NULL,
    [wUpdBy]                  BIGINT        NOT NULL,
    [wIsDestination]          CHAR (1)      CONSTRAINT [DF__ePrivateP__wIsDe__505E47B2] DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_ePrivatePlaneRouteDtl] PRIMARY KEY CLUSTERED ([RowID] ASC)
);





