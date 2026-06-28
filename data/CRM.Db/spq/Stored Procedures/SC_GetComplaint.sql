
CREATE PROCEDURE [spq].[SC_GetComplaint]
    @pRowID BIGINT ,
    @pCode INT = 0 OUTPUT ,
    @pMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      
		
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
            wStatus,
            wCrtDt,
            wCrtBy,
            wUpdDt,
            wUpdBy,
            wCancelRemark,
            wIntroduction
        FROM dbo.eComplaint c
        WHERE c.RowID = @pRowID
            AND c.wStatus = 'A'; 
    END;