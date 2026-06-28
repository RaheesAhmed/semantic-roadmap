CREATE TABLE [dbo].[eDeptReqRoom] (
    [RowID]              BIGINT           NOT NULL,
    [wRequestNo]         VARCHAR (30)     NOT NULL,
    [wRequestDepartment] VARCHAR (30)     NOT NULL,
    [wAgentCodeIn]       VARCHAR (14)     NOT NULL,
    [wHotelRid]          BIGINT           NOT NULL,
    [wRoomRid]           BIGINT           NOT NULL,
    [wBigBedQty]         INT              DEFAULT ((0)) NOT NULL,
    [wTwinBedQty]        INT              DEFAULT ((0)) NOT NULL,
    [wSuiteRoom1Qty]     INT              DEFAULT ((0)) NOT NULL,
    [wDayOfStay]         INT              NOT NULL,
    [wStartDate]         DATE             NOT NULL,
    [wEndDate]           DATE             NOT NULL,
    [wRemark]            NVARCHAR (4000)  NULL,
    [wStaffFollowedRid]  BIGINT           NOT NULL,
    [wDeptFollowedCode]  VARCHAR (20)     NOT NULL,
    [wStatus]            VARCHAR (20)     NOT NULL,
    [wRespFlag]          CHAR (1)         DEFAULT ('Y') NOT NULL,
    [wCrtDt]             DATETIME2 (7)    NOT NULL,
    [wCrtBy]             BIGINT           NOT NULL,
    [wUpdDt]             DATETIME2 (7)    NOT NULL,
    [wUpdBy]             BIGINT           NOT NULL,
    [wEventRid]          BIGINT           DEFAULT ((0)) NOT NULL,
    [wIsNewReqRoom]      CHAR (1)         CONSTRAINT [DF__eDeptReqR__wIsNe__395AE6C9] DEFAULT ('N') NOT NULL,
    [wIsCancel]          CHAR (1)         CONSTRAINT [DF__eDeptReqR__wIsCa__6168D823] DEFAULT ('N') NOT NULL,
    [wCancelDt]          DATETIME2 (7)    NULL,
    [wTotalAmt]          NUMERIC (18, 4)  CONSTRAINT [DF__eDeptReqR__wTota__625CFC5C] DEFAULT ((0)) NOT NULL,
    [wSuiteRoom2Qty]     INT              DEFAULT ((0)) NOT NULL,
    [wSuiteRoom3Qty]     INT              DEFAULT ((0)) NOT NULL,
    [wApplyStaffRid]     BIGINT           DEFAULT ((0)) NOT NULL,
    [wApplyDepartment]   VARCHAR (20)     CONSTRAINT [DF_eDeptReqRoom_wRequestDept] DEFAULT ('') NOT NULL,
    [wGUID]              UNIQUEIDENTIFIER DEFAULT (newid()) NOT NULL,
    [wReqStatus]         VARCHAR (20)     DEFAULT ('') NOT NULL,
    [wIsExtRoom]         CHAR (1)         DEFAULT ('N') NOT NULL,
    PRIMARY KEY CLUSTERED ([RowID] ASC)
);














GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'特別事件(mEvent.RowID)', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptReqRoom', @level2type = N'COLUMN', @level2name = N'wEventRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'需要提供房間的部門', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptReqRoom', @level2type = N'COLUMN', @level2name = N'wRequestDepartment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'要求同事（申請人）', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptReqRoom', @level2type = N'COLUMN', @level2name = N'wApplyStaffRid';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'要求部門（申請部門，一般是登錄者所有的部門）', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptReqRoom', @level2type = N'COLUMN', @level2name = N'wApplyDepartment';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'需求狀態', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptReqRoom', @level2type = N'COLUMN', @level2name = N'wReqStatus';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'是否續房', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptReqRoom', @level2type = N'COLUMN', @level2name = N'wIsExtRoom';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'記錄修改標識', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eDeptReqRoom', @level2type = N'COLUMN', @level2name = N'wGUID';

