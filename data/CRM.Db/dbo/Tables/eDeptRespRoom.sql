CREATE TABLE [dbo].[eDeptRespRoom] (
    [RowID]           BIGINT           NOT NULL,
    [wHotelRid]       BIGINT           NOT NULL,
    [wRoomRid]        BIGINT           NOT NULL,
    [wBigBedQty]      INT              DEFAULT ((0)) NOT NULL,
    [wTwinBedQty]     INT              DEFAULT ((0)) NOT NULL,
    [wSuiteRoom1Qty]  INT              DEFAULT ((0)) NOT NULL,
    [wDayOfStay]      INT              NOT NULL,
    [wStartDate]      DATE             NOT NULL,
    [wEndDate]        DATE             NOT NULL,
    [wStatus]         VARCHAR (20)     NOT NULL,
    [wRepStatus]      VARCHAR (20)     NOT NULL,
    [wRemark]         NVARCHAR (4000)  NULL,
    [wCrtDt]          DATETIME2 (7)    NOT NULL,
    [wCrtBy]          BIGINT           NOT NULL,
    [wUpdDt]          DATETIME2 (7)    NOT NULL,
    [wUpdBy]          BIGINT           NOT NULL,
    [wDeptReqRoomRid] BIGINT           DEFAULT ((0)) NOT NULL,
    [wIsApproved]     CHAR (1)         DEFAULT ('N') NOT NULL,
    [wTotalAmount]    NUMERIC (18, 4)  DEFAULT ((0)) NOT NULL,
    [wDeptStatus]     VARCHAR (20)     CONSTRAINT [DF__eDeptResp__wDept__0996C50E] DEFAULT ('') NOT NULL,
    [wBookingRid]     BIGINT           DEFAULT ((0)) NOT NULL,
    [wCancelReason]   NVARCHAR (500)   DEFAULT ('') NOT NULL,
    [wSuiteRoom2Qty]  INT              DEFAULT ((0)) NOT NULL,
    [wSuiteRoom3Qty]  INT              DEFAULT ((0)) NOT NULL,
    [wGUID]           UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [wIsExtRoom]      CHAR (1)         DEFAULT ('N') NOT NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'金額', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptRespRoom', @level2type = N'COLUMN', @level2name = N'wTotalAmount';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'已批核', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptRespRoom', @level2type = N'COLUMN', @level2name = N'wIsApproved';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'酒店訂單eBookingHotel.wBookingRid', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptRespRoom', @level2type = N'COLUMN', @level2name = N'wBookingRid';


GO
CREATE NONCLUSTERED INDEX [IX_eDeptRespRoom_01]
    ON [dbo].[eDeptRespRoom]([wStatus] ASC, [wRepStatus] ASC, [wDeptStatus] ASC)
    INCLUDE([wHotelRid], [wDeptReqRoomRid], [wStartDate], [wEndDate])
    ON [CRM_IDX];


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'是否續房', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptRespRoom', @level2type = N'COLUMN', @level2name = N'wIsExtRoom';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'記錄修改標識', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptRespRoom', @level2type = N'COLUMN', @level2name = N'wGUID';

