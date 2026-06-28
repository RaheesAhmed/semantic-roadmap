

CREATE PROCEDURE [spq].[GetProcessLst_Other]
    @pScopeType VARCHAR(30) ,
    @pProcessType VARCHAR(30)
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  p_t.RowID ,
                p_t.wScopeType ,
                p_t.wProcessType ,
                p_t.wCurrectStepValue ,
                p_t.wPreviousStepValue ,
                p_t.wStatus ,
                p_t.wUpdDt ,
                p_t.wCrtDt
        FROM    dbo.mProcess p_t
        WHERE   p_t.wScopeType = @pScopeType
                AND p_t.wProcessType = @pProcessType
                AND p_t.wStatus = 'A';
    END;