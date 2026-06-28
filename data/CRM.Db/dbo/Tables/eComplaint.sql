CREATE TABLE [dbo].[eComplaint] (
    [RowID]                BIGINT          NOT NULL,
    [wTranDt]              DATETIME2 (7)   NOT NULL,
    [wRefNo]               VARCHAR (30)    NOT NULL,
    [wAgentCodeIn]         VARCHAR (14)    NOT NULL,
    [wComplainantName]     NVARCHAR (50)   NOT NULL,
    [wPersonRid]           BIGINT          CONSTRAINT [DF_eComplaint_wPersonRid] DEFAULT ((-1)) NOT NULL,
    [wComplainantNickname] NVARCHAR (50)   NOT NULL,
    [wComplainantTitle]    NVARCHAR (30)   NOT NULL,
    [wComplainantTel]      VARCHAR (100)   NOT NULL,
    [wType]                VARCHAR (30)    NOT NULL,
    [wChannel]             VARCHAR (30)    NOT NULL,
    [wReceivedBy]          BIGINT          CONSTRAINT [DF_eComplaint_wReceiveStaffNo] DEFAULT ((-1)) NOT NULL,
    [wReceivedDeptCd]      VARCHAR (30)    CONSTRAINT [DF_eComplaint_wReceiveDeptCd] DEFAULT ('') NOT NULL,
    [wReceivedLocation]    NVARCHAR (30)   CONSTRAINT [DF_eComplaint_wReceiveLocation] DEFAULT ('') NOT NULL,
    [wComplainBy]          BIGINT          CONSTRAINT [DF_eComplaint_wComplainStaffNo] DEFAULT ((-1)) NOT NULL,
    [wComplainDeptCd]      VARCHAR (30)    CONSTRAINT [DF_Table_1_wReceiveDeptCd1] DEFAULT ('') NOT NULL,
    [wComplainLocation]    NVARCHAR (30)   CONSTRAINT [DF_Table_1_wReceiveLocation1] DEFAULT ('') NOT NULL,
    [wComplainCompNo]      INT             CONSTRAINT [DF_eComplaint_wComplainCompNo] DEFAULT ((-1)) NOT NULL,
    [wContent]             NVARCHAR (2000) NOT NULL,
    [wComplaintStatus]     VARCHAR (30)    NOT NULL,
    [wStatus]              CHAR (1)        NOT NULL,
    [wCrtDt]               DATETIME2 (7)   NOT NULL,
    [wCrtBy]               BIGINT          NOT NULL,
    [wUpdDt]               DATETIME2 (7)   NOT NULL,
    [wUpdBy]               BIGINT          NOT NULL,
    [wCancelRemark]        NVARCHAR (500)  CONSTRAINT [DF_eComplaint_wCancelRemark] DEFAULT ('') NOT NULL,
    [wIntroduction]        NVARCHAR (2000) CONSTRAINT [DF__eComplain__wIntr__49E6544D] DEFAULT ('') NOT NULL,
    [wDealDt]              DATETIME2 (7)   NOT NULL,
    CONSTRAINT [PK_eComplaint] PRIMARY KEY CLUSTERED ([RowID] ASC)
);








GO



GO



GO



GO



GO



GO



GO



GO



GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'簡介', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eComplaint', @level2type = N'COLUMN', @level2name = N'wIntroduction';


GO
EXECUTE sp_addextendedproperty @name = N'MS_Description', @value = N'投訴處理時間（第一次狀態轉換，同一狀態UpdDt，此值不變）', @level0type = N'SCHEMA', @level0name = N'dbo', @level1type = N'TABLE', @level1name = N'eComplaint', @level2type = N'COLUMN', @level2name = N'wDealDt';

