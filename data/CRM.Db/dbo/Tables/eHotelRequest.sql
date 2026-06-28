CREATE TABLE [dbo].[eHotelRequest] (
    [RowID]                BIGINT         NOT NULL,
    [wRequestNo]           VARCHAR (30)   NOT NULL,
    [wReqCounterRid]       BIGINT         NOT NULL,
    [wDebitCounterRid]     BIGINT         NULL,
    [wReqAgentCodeIn]      VARCHAR (14)   NOT NULL,
    [wDebitAgentCodeIn]    VARCHAR (14)   NULL,
    [wReqCustomerRid]      BIGINT         NULL,
    [wDebitCustomerRid]    BIGINT         NULL,
    [wReqDepartment]       VARCHAR (30)   NULL,
    [wReqUserRid]          BIGINT         NULL,
    [wAsstBooker]          NVARCHAR (50)  NULL,
    [wAssBookerTel]        VARCHAR (100)  NULL,
    [wApprovalAgentCodeIn] VARCHAR (14)   NULL,
    [wRegion]              VARCHAR (3)    NOT NULL,
    [wNumberOfRoom]        INT            NOT NULL,
    [wStartDate]           DATE           NOT NULL,
    [wEndDate]             DATE           NOT NULL,
    [wDayOfStay]           INT            NOT NULL,
    [wHotelCodeSCV]        VARCHAR (1000) NOT NULL,
    [wIsAgentHotel]        CHAR (1)       NOT NULL,
    [wBedType]             VARCHAR (2)    NOT NULL,
    [wLockCounterRid]      BIGINT         NULL,
    [wStatus]              VARCHAR (3)    NOT NULL,
    [wRemark]              NVARCHAR (500) CONSTRAINT [DF_Table_1_wSeqNo] DEFAULT ((0)) NOT NULL,
    [wCrtDt]               DATETIME2 (7)  NOT NULL,
    [wCrtBy]               BIGINT         NOT NULL,
    [wUpdDt]               DATETIME2 (7)  NOT NULL,
    [wUpdBy]               BIGINT         NOT NULL,
    [wCounterRid]          BIGINT         NOT NULL,
    [wTravePkgRid]         BIGINT         DEFAULT ((-1)) NOT NULL,
    [wEventCodeRid]        BIGINT         CONSTRAINT [DF_eHotelRequest_wEventCodeRid] DEFAULT ((-1)) NOT NULL,
    [wAsstBookerEmail]     NVARCHAR (50)  CONSTRAINT [DF_eHotelRequest_wAsstBookerEmail] DEFAULT ('') NOT NULL,
    [wDeptFollwedCd]       VARCHAR (30)   CONSTRAINT [DF_eHotelRequest_wDeptFollwedCd] DEFAULT ('') NOT NULL,
    [wStaffFollwedRid]     BIGINT         CONSTRAINT [DF_eHotelRequest_wStaffFollwedRid] DEFAULT ((-1)) NOT NULL,
    [wStaffTelephone]      VARCHAR (100)  CONSTRAINT [DF_eHotelRequest_wStaffTelephone] DEFAULT ('') NOT NULL,
    [wOwnerAuthTelephone]  VARCHAR (100)  CONSTRAINT [DF_eHotelRequest_wOwnerAuthTelephone] DEFAULT ('') NOT NULL,
    [wCancelReasonCd]      VARCHAR (30)   NULL,
    [wOtherReason]         NVARCHAR (200) DEFAULT (NULL) NULL,
    [wCancelDt]            DATETIME2 (7)  NULL,
    [wCancelBy]            BIGINT         NULL,
    [wUnqualifiedRid]      BIGINT         NULL,
    [wIsSelectRoom]        CHAR (1)       DEFAULT ('N') NOT NULL,
    [wCoordinator]         NVARCHAR (50)  DEFAULT ('') NOT NULL,
    [wIsUser]              CHAR (1)       DEFAULT ('N') NOT NULL,
    [wUser]                NVARCHAR (50)  DEFAULT ('') NOT NULL,
    [wHotelRidSVC]         VARCHAR (2000) DEFAULT ('') NULL,
    CONSTRAINT [PK_eHotelRequest] PRIMARY KEY CLUSTERED ([RowID] ASC)
);






















GO





GO



GO


