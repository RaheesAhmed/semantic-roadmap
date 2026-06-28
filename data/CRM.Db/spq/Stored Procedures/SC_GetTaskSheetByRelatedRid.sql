CREATE PROCEDURE [spq].[SC_GetTaskSheetByRelatedRid]
    (
      /*
		exec [spq].[SC_GetTaskSheetByRelatedRid] 'eAdvice', 99000000010056
	*/@pRelatedType VARCHAR(30) ,
      @pRelatedRid BIGINT ,  
      @pCode INT = 0 OUTPUT ,
      @pMsg NVARCHAR(200) = '' OUTPUT
    )
AS
    BEGIN
        SET NOCOUNT ON;
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;

        SELECT  ts.RowID ,
                ts.wCounterRid ,
                ts.wDeptCd ,
                ts.wDate ,
                ts.wTaskType ,
                ts.wSubTaskType ,
                ts.wRelateAgentCodeIn ,
                ts.wIsInhouse ,
                ts.wContent ,
                ts.wRemark ,
                ts.wFollowUpDt ,
                ts.wFollowUpBy ,
                ts.wTaskSheetStatus ,
                ts.wCrtDt ,
                ts.wCrtBy ,
                ts.wUpdDt ,
                ts.wUpdBy ,
                ts.wRelatedType ,
                ts.wRelatedRid
        FROM    dbo.eTaskSheet ts
        WHERE   ts.wRelatedType = @pRelatedType
                AND ts.wRelatedRid = @pRelatedRid
                AND ts.wStatus = 'A'
        ORDER BY ts.wUpdDt;
        
    END;