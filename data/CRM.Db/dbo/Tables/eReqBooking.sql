CREATE TABLE [dbo].[eReqBooking] (
    [RowID]          BIGINT           NOT NULL,
    [wGUID]          UNIQUEIDENTIFIER NOT NULL,
    [wBookingType]   VARCHAR (30)     NOT NULL,
    [wRefTable]      VARCHAR (50)     NOT NULL,
    [wRefRid]        BIGINT           NOT NULL,
    [wRefNo]         VARCHAR (50)     NOT NULL,
    [wAgentCodeIn]   VARCHAR (14)     NOT NULL,
    [wReqDeptCd]     VARCHAR (30)     NOT NULL,
    [wReqUserRid]    BIGINT           NOT NULL,
    [wFollowDeptCd]  VARCHAR (30)     NOT NULL,
    [wFollowUserRid] BIGINT           NOT NULL,
    [wReqStatus]     VARCHAR (10)     NOT NULL,
    [wStatus]        CHAR (1)         NOT NULL,
    [wCrtBy]         BIGINT           NOT NULL,
    [wCrtDt]         DATETIME2 (7)    NOT NULL,
    [wUpdBy]         BIGINT           NOT NULL,
    [wUpdDt]         DATETIME2 (7)    NOT NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);

