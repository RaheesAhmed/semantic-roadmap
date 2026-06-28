CREATE TABLE [dbo].[eBookingHotel] (
    [RowID]            BIGINT         NOT NULL,
    [wBookingRid]      BIGINT         NOT NULL,
    [wRequestRid]      BIGINT         NOT NULL,
    [wUseTravelAgency] CHAR (1)       NOT NULL,
    [wTravelAgencyRid] BIGINT         NOT NULL,
    [wRoomInProgress]  INT            NOT NULL,
    [wRoomCompleted]   INT            NOT NULL,
    [wRoomNotArrange]  INT            NOT NULL,
    [wRoomCancelled]   INT            NOT NULL,
    [wRoomUnQualified] INT            CONSTRAINT [DF_eBookingHotel_wRoomUnQualified] DEFAULT ((0)) NOT NULL,
    [wQuantity]        INT            NOT NULL,
    [wRegion]          VARCHAR (3)    NOT NULL,
    [wIsAgentHotel]    CHAR (1)       NOT NULL,
    [wStartDate]       DATE           NOT NULL,
    [wEndDate]         DATE           NOT NULL,
    [wDayOfStay]       INT            NOT NULL,
    [wBedType]         VARCHAR (3)    NOT NULL,
    [wPaymentMethod]   VARCHAR (30)   NOT NULL,
    [wReceiptNo]       NVARCHAR (50)  CONSTRAINT [DF_eBookingHotel_wReceiptNo] DEFAULT ('') NOT NULL,
    [wRemark]          NVARCHAR (500) NOT NULL,
    [wSeqNo]           INT            CONSTRAINT [DF_eBookingHotelRoom_wSeqNo] DEFAULT ((0)) NOT NULL,
    [wCrtDt]           DATETIME2 (7)  NOT NULL,
    [wCrtBy]           BIGINT         NOT NULL,
    [wUpdDt]           DATETIME2 (7)  NOT NULL,
    [wUpdBy]           BIGINT         NOT NULL,
    [wBookingStatus]   VARCHAR (3)    CONSTRAINT [DF_eBookingHotel_wBookingStatus] DEFAULT ('P') NOT NULL,
    [wCounterRid]      BIGINT         CONSTRAINT [DF_eBookingHotel_wCounterRid_1] DEFAULT ((-1)) NOT NULL,
    [wStatus]          CHAR (1)       CONSTRAINT [DF_eBookingHotel_wStatus] DEFAULT ('A') NOT NULL,
    [wSource]          VARCHAR (30)   DEFAULT ('CRM') NOT NULL,
    CONSTRAINT [PK_eBookingHotel] PRIMARY KEY CLUSTERED ([RowID] ASC)
);
















GO





GO



GO



GO



GO



GO



GO



GO


