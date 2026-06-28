
CREATE PROCEDURE [spq].[GetWarehouse] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  w_t.RowID ,
                w_t.wDepartmentCode ,
                w_t.wCName ,
                w_t.wEName ,
                w_t.wCounterRid ,
                w_t.wIsDefault ,
                w_t.wStatus ,
                w_t.wCrtDt ,
                w_t.wUpdDt ,
                'N' AS RecordState
        FROM    dbo.mWarehouse w_t
        WHERE   @pRowID = w_t.RowID;                                                 
    END;