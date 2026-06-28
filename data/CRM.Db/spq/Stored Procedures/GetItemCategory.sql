
	CREATE PROCEDURE [spq].[GetItemCategory]
		@pRowID BIGINT
	AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT ic_t.RowID, ic_t.wCName, ic_t.wEName, ic_t.wStatus, ic_t.wCrtDt, ic_t.wUpdDt, 'N' AS RecordState  FROM dbo.mItemCategory ic_t
		WHERE @pRowID = ic_t.RowID                                                 
    END;