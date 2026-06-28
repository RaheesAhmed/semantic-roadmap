CREATE TABLE [dbo].[ePassengerDetails] (
    [RowID]                   BIGINT          NOT NULL,
    [wBookingRid]             BIGINT          NOT NULL,
    [wCasinoCardRid]          BIGINT          CONSTRAINT [DF_ePassengerDetails_wCasinoCardRid] DEFAULT ((-1)) NOT NULL,
    [wRoomBookingRid]         BIGINT          CONSTRAINT [DF_ePassengerDetails_wRoomBookingRid] DEFAULT ((-1)) NOT NULL,
    [wClientTicketNo]         VARCHAR (50)    CONSTRAINT [DF_ePassengerInfo_wClientTicketNo] DEFAULT ('') NOT NULL,
    [wDepartFlightNo]         VARCHAR (20)    CONSTRAINT [DF_ePassengerInfo_wDepartFlightNo] DEFAULT ('') NOT NULL,
    [wTakeOffDt]              DATETIME2 (7)   CONSTRAINT [DF_ePassengerInfo_wTakeOffDt] DEFAULT (getdate()) NOT NULL,
    [wDestination]            NVARCHAR (200)  CONSTRAINT [DF_ePassengerInfo_wDestination] DEFAULT ('') NOT NULL,
    [wRequesterAcc]           BIGINT          CONSTRAINT [DF_ePassengerInfo_wRequesterAcc] DEFAULT ((0)) NOT NULL,
    [wPersonRid]              BIGINT          CONSTRAINT [DF_ePassengerInfo_wPersonRid] DEFAULT ((0)) NOT NULL,
    [wRemark]                 NVARCHAR (500)  CONSTRAINT [DF_ePassengerInfo_wRemark] DEFAULT ('') NOT NULL,
    [wStatus]                 VARCHAR (10)    CONSTRAINT [DF_ePassengerInfo_wStatus] DEFAULT ('P') NOT NULL,
    [wCrtBy]                  BIGINT          CONSTRAINT [DF_ePassengerInfo_wCrtBy] DEFAULT ((0)) NOT NULL,
    [wCrtDt]                  DATETIME2 (7)   CONSTRAINT [DF_ePassengerInfo_wCrtDt] DEFAULT (getdate()) NOT NULL,
    [wUpdDt]                  DATETIME2 (7)   CONSTRAINT [DF_ePassengerInfo_wUpdDt] DEFAULT (getdate()) NOT NULL,
    [wUpdBy]                  BIGINT          CONSTRAINT [DF_ePassengerInfo_wUpdBy] DEFAULT ((0)) NOT NULL,
    [wType]                   VARCHAR (25)    CONSTRAINT [DF_ePassengerInfo_wType] DEFAULT ('') NOT NULL,
    [wApplicationType]        VARCHAR (10)    CONSTRAINT [DF__ePassenge__wApplicationType] DEFAULT ('') NULL,
    [wApplicationStatus]      VARCHAR (10)    CONSTRAINT [DF__ePassenge__wApplicationStatus] DEFAULT ('') NULL,
    [wAmount]                 NUMERIC (18, 4) CONSTRAINT [DF__ePassenge__wAmount] DEFAULT ((0)) NULL,
    [wCost]                   NUMERIC (18, 4) CONSTRAINT [DF_ePassengerDetails_wCost] DEFAULT ((0)) NOT NULL,
    [wSeqNo]                  INT             CONSTRAINT [DF__ePassenge__wSeqNo] DEFAULT ((-1)) NULL,
    [wCancelDebitDt]          DATETIME2 (7)   NULL,
    [wCancelReasonCd]         VARCHAR (30)    CONSTRAINT [DF_ePassengerDetails_wCancelReasonCd] DEFAULT (' ') NULL,
    [wCancelBy]               BIGINT          NULL,
    [wCancelDt]               DATETIME2 (7)   NULL,
    [wPassengerBookingStatus] VARCHAR (10)    CONSTRAINT [DF_ePassengerDetails_wPassengerBookingStatus] DEFAULT ('P') NOT NULL,
    [wChangeOrderCount]       INT             CONSTRAINT [DF_ePassengerDetails_wChangeOrderCount] DEFAULT ((0)) NOT NULL,
    [wIsWaiting]              CHAR (1)        CONSTRAINT [DF_ePassengerDetails_wIsWaiting] DEFAULT ('N') NOT NULL,
    [wRouteRid]               BIGINT          CONSTRAINT [DF_ePassengerDetails_wRouteRid] DEFAULT ((-1)) NOT NULL,
    [wOtherReason]            NVARCHAR (200)  CONSTRAINT [DF_ePassengerDetails_wOtherReason] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ePassengerDetails] PRIMARY KEY CLUSTERED ([RowID] ASC)
);
















GO



GO



GO
CREATE NONCLUSTERED INDEX [PI_ePassengerDetails_01]
    ON [dbo].[ePassengerDetails]([wRoomBookingRid] ASC);


GO
CREATE NONCLUSTERED INDEX [PI_ePassengerDetails_02]
    ON [dbo].[ePassengerDetails]([wBookingRid] ASC, [wStatus] ASC);




GO
CREATE NONCLUSTERED INDEX [PI_ePassengerDetails_03]
    ON [dbo].[ePassengerDetails]([wStatus] ASC)
    INCLUDE([wBookingRid]);

