CREATE PROCEDURE [spq].[GetBirthday]
	@pRowID BIGINT
AS
BEGIN
    SET NOCOUNT ON;	  	
				
    SELECT 
        RowID,
        wVIPPersonRid,
        wYear,
        wIsLeapMonth,
        wGiftType,
        wRegion,
        wFollowDeptRid,
        wFollowTeamRid,
        wFollowUsrRid,
        wIsPushWeChat,
        wIsRefusedContact,
        wPresetGiftDt,
        wCreditAmt,
        wApprovedStatus,
        wGiftStatus,
        wSMSStatus,
        wStatus,
        wCrtBy,
        wCrtDt,
        wUpdBy,
        wUpdDt
    FROM dbo.eBirthday
    WHERE @pRowID = RowID                                                 
END;