CREATE TABLE [dbo].[eReqBookingFilterLog] (
    [wUserRid]        BIGINT         NOT NULL,
    [wProgressQty]    INT            NOT NULL,
    [wExpirationDate] DATE           NOT NULL,
    [wUpdDt]          DATETIME2 (7)  NOT NULL,
    [wAgentCodeIn]    NVARCHAR (100) NOT NULL,
    [wBookingType]    VARCHAR (30)   NOT NULL,
    [wReqUser]        BIGINT         NOT NULL,
    [wReqDeptCd]      VARCHAR (30)   NOT NULL,
    [wReqStatus]      VARCHAR (10)   NOT NULL,
    [wStartDate]      VARCHAR (20)   NOT NULL,
    [wEndDate]        VARCHAR (20)   NOT NULL,
    [wHotelRid]       BIGINT         NOT NULL,
    PRIMARY KEY CLUSTERED ([wUserRid] ASC)
);

