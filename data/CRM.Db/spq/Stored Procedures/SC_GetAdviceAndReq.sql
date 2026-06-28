
CREATE PROCEDURE [spq].[SC_GetAdviceAndReq]
    @pRowID BIGINT ,
    @pCode INT = 0 OUTPUT ,
    @pMsg NVARCHAR(200) = '' OUTPUT
AS
    BEGIN
        SET NOCOUNT ON;

        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;      
			  
        SELECT  a.RowID ,
                a.wAim ,
                a.wDate ,
                a.wIsHighPriority ,
                a.wAgentCodeIn ,
                a.wReceivedDeptCd ,
                a.wReceivedBy ,
                a.wType ,
                a.wSubType ,
                a.wContent ,
                a.wAdviceStatus ,
                a.wUpdDt ,
                a.wUpdBy
        FROM    dbo.eAdvice a
        WHERE   a.RowID = @pRowID
                AND a.wStatus = 'A';
    END;