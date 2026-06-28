

Create VIEW [vipRpt].[vwGift]
AS
    SELECT     a.rowId, 
				a.wCompNo, 
				a.wReqAgentCodeIn, 
				a.wDate, 
				a.wRecipient, 
				a.wCurrCode, 
				a.wAmount, 
				a.wRemark, 
				a.wIsReceived, 
				a.wCost, 
				a.wStatus, 
				a.wUpdDt, 
				a.wReqCounterRid, 
				a.wReqStaffRid, 
				a.wReasonCd   ,
				a.wReqDeptCd,
				wType,
				wSubType
	FROM            dbo.eGift a