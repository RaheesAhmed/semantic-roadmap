CREATE PROCEDURE [spq].[GetComplaintForShare] 
(
    @pRowID BIGINT
)
AS
    BEGIN
        SET NOCOUNT ON;

        SELECT
            RowID, 
            wTranDt, 
            wRefNo, 
            wAgentCodeIn, 
            wComplainantName, 
            wPersonRid, 
            wComplainantNickname, 
            wComplainantTitle, 
            wComplainantTel, 
            wType, 
            wChannel,
            wReceivedBy, 
            wReceivedDeptCd, 
            wReceivedLocation, 
            wComplainBy, 
            wComplainDeptCd, 
            wComplainLocation, 
            wComplainCompNo, 
            wContent, 
            wComplaintStatus, 
            wStatus, wCrtDt, 
            wCrtBy, 
            wUpdDt, 
            wUpdBy, 
            wCancelRemark, 
            wIntroduction
        FROM dbo.eComplaint
        WHERE RowID = @pRowID;
    END;