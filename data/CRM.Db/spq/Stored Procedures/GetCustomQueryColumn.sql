
CREATE PROCEDURE [spq].[GetCustomQueryColumn] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  cqc_t.RowID ,
                cqc_t.wCustomQueryRid ,
                cqc_t.wColumnCode ,
                cqc_t.wIsVisible ,
                cqc_t.wAllowSelect ,
                cqc_t.wAllowSortAcsc ,
                cqc_t.wAllowSortDesc ,
                cqc_t.wStatus ,
                cqc_t.wCrtBy ,
                cqc_t.wCrtDt ,
                cqc_t.wUpdBy ,
                cqc_t.wUpdDt ,
                'N' AS RecordState
        FROM    dbo.mCustomQueryColumn cqc_t
        WHERE   @pRowID = cqc_t.RowID;                                                 
    END;