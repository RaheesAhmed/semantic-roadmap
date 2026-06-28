CREATE PROCEDURE [spq].[GetComplaint] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

	-- Insert statements for procedure here
	-- PRINT dbo.fnGetAllFieldNameInTable('eComplaint', 'c', 'N', 'N', 'N', '')
        SELECT  c.RowID ,
                c.wTranDt ,
                c.wRefNo ,
                c.wAgentCodeIn ,
                c.wComplainantName ,
                c.wPersonRid ,
                c.wComplainantNickname ,
                c.wComplainantTitle ,
                c.wComplainantTel ,
                c.wType ,
                c.wChannel ,
                c.wReceivedBy ,
                c.wReceivedDeptCd ,
                c.wReceivedLocation ,
                c.wComplainBy ,
                c.wComplainDeptCd ,
                c.wComplainLocation ,
                c.wComplainCompNo ,
                c.wContent ,
                c.wComplaintStatus ,
                c.wCancelRemark ,
                c.wStatus ,
                c.wCrtDt ,
                c.wCrtBy ,
                c.wUpdDt ,
                c.wUpdBy,
                c.wIntroduction
        FROM    dbo.eComplaint c
        WHERE   c.RowID = @pRowID;
    END;