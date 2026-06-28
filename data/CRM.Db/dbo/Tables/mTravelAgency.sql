CREATE TABLE [dbo].[mTravelAgency] (
    [RowID]           BIGINT        NOT NULL,
    [wCode]           NVARCHAR (30) NOT NULL,
    [wName]           NVARCHAR (30) NOT NULL,
    [wIsHotel]        CHAR (1)      NOT NULL,
    [wIsAirTic]       CHAR (1)      NOT NULL,
    [wIsShowTic]      CHAR (1)      NOT NULL,
    [wSeqNo]          INT           NOT NULL,
    [wStatus]         CHAR (1)      NOT NULL,
    [wCrtDt]          DATETIME2 (7) NOT NULL,
    [wCrtBy]          BIGINT        NOT NULL,
    [wUpdDt]          DATETIME2 (7) NOT NULL,
    [wUpdBy]          BIGINT        NOT NULL,
    [wIsTourGuide]    CHAR (1)      CONSTRAINT [DF_mTravelAgency_wIsTourGuide] DEFAULT ('N') NOT NULL,
    [wIsLeading]      CHAR (1)      CONSTRAINT [DF_mTravelAgency_wIsLeading] DEFAULT ('N') NOT NULL,
    [wIsPickup]       CHAR (1)      CONSTRAINT [DF_mTravelAgency_wIsPickup] DEFAULT ('N') NOT NULL,
    [wIsHelicopter]   CHAR (1)      DEFAULT ('N') NOT NULL,
    [wIsPrivatePlane] CHAR (1)      DEFAULT ('N') NOT NULL,
    [wIsRestaurant]   CHAR (1)      DEFAULT ('N') NOT NULL,
    [wIsCheckIn]      CHAR (1)      DEFAULT ('N') NOT NULL,
    [wIsVisa]         CHAR (1)      DEFAULT ('N') NOT NULL,
    [wIsShip]         CHAR (1)      DEFAULT ('N') NOT NULL,
    [wIsTravelPac]    CHAR (1)      DEFAULT ('N') NOT NULL,
    [wIsOtherExp]     CHAR (1)      DEFAULT ('N') NOT NULL,
    CONSTRAINT [PK_mTravelAgency] PRIMARY KEY CLUSTERED ([RowID] ASC)
);











