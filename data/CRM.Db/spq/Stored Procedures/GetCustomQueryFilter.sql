
CREATE PROCEDURE [spq].[GetCustomQueryFilter] @pRowID BIGINT
AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT  cqf_t.RowID ,
                cqf_t.wCustomQueryRid ,
                cqf_t.wFilterCode ,
                cqf_t.wIsVisible ,
                cqf_t.wDefaultValue ,
                cqf_t.wStatus ,
                cqf_t.wCrtBy ,
                cqf_t.wCrtDt ,
                cqf_t.wUpdBy ,
                cqf_t.wUpdDt ,
                'N' AS RecordState
        FROM    dbo.mCustomQueryFilter cqf_t
        WHERE   @pRowID = cqf_t.RowID;                                                 
    END;