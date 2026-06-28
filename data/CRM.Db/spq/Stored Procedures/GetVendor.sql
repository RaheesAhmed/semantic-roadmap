
	CREATE PROCEDURE [spq].[GetVendor]
		@pRowID BIGINT
	AS
    BEGIN
        SET NOCOUNT ON;	  	
				
        IF @@trancount = 0
            SET TRANSACTION ISOLATION LEVEL SNAPSHOT;        
	
        SELECT v_t.RowID, v_t.wCName, v_t.wEName, v_t.wAddress, v_t.wTel, v_t.wGracePeriod, v_t.wStatus, v_t.wCrtDt, v_t.wUpdDt, 'N' AS RecordState  FROM dbo.mVendor v_t
		WHERE @pRowID = v_t.RowID                                                 
    END;