CREATE PROCEDURE [spq].[SC_GetComplaintFollowByComplaintRid]
    (
      /*
		exec [spq].[SC_GetComplaintFollowByComplaintRid] 99000000010007
	  */
      @pComplaintRid BIGINT ,
      @pCode INT = 0 OUTPUT ,
      @pMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SELECT  RowID ,
                wTranDt ,
                wFollowBy ,
				wFollowDeptCd ,
                wContent ,
                wSolveContent ,
                wPreventContent ,
                wStatus ,
				wUpdBy
        FROM    dbo.eComplaintFollow cf
        WHERE   cf.wComplaintRid = @pComplaintRid
        ORDER BY cf.wUpdDt;
        
    END;