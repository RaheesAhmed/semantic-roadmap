CREATE TABLE [dbo].[ePassengerTravelDocDetail] (
    [RowID]                BIGINT        NOT NULL,
    [wPassengerDetailsRid] BIGINT        NOT NULL,
    [wPersonTravelDocRid]  BIGINT        NOT NULL,
    [wUpdDt]               DATETIME2 (7) NOT NULL,
    [wUpdBy]               NCHAR (10)    NOT NULL
);




GO
CREATE NONCLUSTERED INDEX [PI_ePassengerTravelDocDetail_01]
    ON [dbo].[ePassengerTravelDocDetail]([wPassengerDetailsRid] ASC);

