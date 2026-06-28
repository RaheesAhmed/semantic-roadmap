CREATE TABLE [dbo].[eAllotmentHotel] (
    [RowID]          BIGINT        NOT NULL,
    [wHotelRid]      BIGINT        NOT NULL,
    [wRoomRid]       BIGINT        NOT NULL,
    [wIsSpecialDate] CHAR (1)      CONSTRAINT [DF_eAllotmentHotel_wIsSpecialDate] DEFAULT ('N') NOT NULL,
    [wStartDate]     DATE          NOT NULL,
    [wEndDate]       DATE          NULL,
    [wStatus]        CHAR (1)      NOT NULL,
    [wSeqNo]         INT           NOT NULL,
    [wCrtDt]         DATETIME2 (7) NOT NULL,
    [wCrtBy]         BIGINT        NOT NULL,
    [wUpdDt]         DATETIME2 (7) NOT NULL,
    [wUpdBy]         BIGINT        NOT NULL,
    CONSTRAINT [PK_eAllotmentHotel] PRIMARY KEY CLUSTERED ([RowID] ASC)
);












GO


