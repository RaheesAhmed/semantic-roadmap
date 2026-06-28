CREATE TABLE [dbo].[eReqBookingHotel] (
    [RowID]           BIGINT           NOT NULL,
    [wGUID]           UNIQUEIDENTIFIER NOT NULL,
    [wReqBookingRid]  BIGINT           NOT NULL,
    [wHotelRid]       BIGINT           NOT NULL,
    [wHotelRoomRid]   BIGINT           NOT NULL,
    [wCheckInDate]    DATE             NOT NULL,
    [wCheckOutDate]   DATE             NOT NULL,
    [wBigBedRoomQty]  INT              NOT NULL,
    [wTwinBedRoomQty] INT              NOT NULL,
    [wSuiteRoom1Qty]  INT              NOT NULL,
    [wSuiteRoom2Qty]  INT              NOT NULL,
    [wSuiteRoom3Qty]  INT              NOT NULL,
    [wRemark]         NVARCHAR (4000)  NOT NULL,
    [wStatus]         CHAR (1)         NOT NULL,
    [wCrtBy]          BIGINT           NOT NULL,
    [wCrtDt]          DATETIME2 (7)    NOT NULL,
    [wUpdBy]          BIGINT           NOT NULL,
    [wUpdDt]          DATETIME2 (7)    NOT NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);

