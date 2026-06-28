CREATE PROCEDURE [spq].[GetTaskSheet] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;

	-- Insert statements for procedure here
	-- PRINT dbo.fnGetAllFieldNameInTable('eTaskSheet', 'ts', 'N', 'N', 'N', '')
        SELECT  ts.RowID ,
                ts.wCompNo ,
                ts.wCounterRid ,
                ts.wDeptCd ,
                ts.wUsrRid ,
                ts.wDate ,
                ts.wTaskType ,
                ts.wSubTaskType ,
                ts.wIsInhouse ,
                ts.wContent ,
                ts.wRemark ,
                ts.wRelateAgentCodeIn ,
                ts.wRelatedType ,
                ts.wRelatedRid ,
                ts.wHasDoc ,
                ts.wStatus ,
                ts.wCrtDt ,
                ts.wCrtBy ,
                ts.wUpdDt ,
                ts.wUpdBy ,
                ts.wFollowUpDt ,
                ts.wFollowUpBy ,
                ts.wTaskSheetStatus
        FROM    dbo.eTaskSheet ts
        WHERE   ts.RowID = @pRowID;
    END;