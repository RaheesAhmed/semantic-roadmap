CREATE PROCEDURE [spq].[GetContactTran] 
    @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;
     
        SELECT
            ct.RowID,
            ct.wCompNo,
            ct.wContactTypeName,
            ct.wRefNo,
            ct.wLocation,				
            ct.wCategoryCd,
            ct.wSubCategoryCd,
            ct.wDeptCd,
            ct.wExpAmount,
            ct.wExpAmountCurrCode,
            ct.wDateFrom,
            ct.wDateTo,
            ct.wIsFullDay,
            ct.wContactStatus,
            ct.wRemark,
            ct.wStatus,
            ct.wCrtDt,
            ct.wCrtBy,
            ct.wUpdDt,
            ct.wUpdBy,
            ct.wReason,
            ct.wPurpose,
            ct.wAdviceRid,
            ct.wPeriod,
            ct.wApprover,
            ct.wRegion,
            ct.wAssistantDt,
            ct.wApproverDt,
            EName = u.wName,
            CName = u.wCName
        FROM dbo.eContactTran ct
        LEFT JOIN RollsMary.dbo.mUsr u ON ct.wApprover=u.RowID
        WHERE ct.RowID = @pRowID;
    END;